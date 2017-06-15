package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import Slambda.fn;

using StringTools;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;

/**
  * base-class for data type that that stores sequences of serialized objects
  */
class Bucket<T> {
    /* Constructor Function */
    public function new(path : Path):Void {
        delimiter = '\n'.code;
        this.path = path;
    }

/* === Instance Methods === */

    /**
      * get an Input
      */
    public function input():FileInput {
        return _safe(function() return Fs.openInput( path ));
    }

    /**
      * get an Output
      */
    public function output(append:Bool=false):FileOutput {
        return _safe(function() return Fs.openOutput(path, append));
    }

    /**
      * find all positions of the delimiter in the data
      */
    public function separatorIndices():Array<Int> {
        try {
            var fi = input(), si = [], i = 0;
            if (fi == null)
                return [];
            try {
                var c : Byte;
                while ( true ) {
                    c = fi.readByte();
                    if (c == delimiter)
                        si.push( i );
                    i++;
                }
            }
            catch (e : haxe.io.Eof) {}
            fi.close();
            return si;
        }
        catch (error : Dynamic) {
            if (error.code != null && Std.is(error.code, String)) {
                switch ( error.code ) {
                    case 'ENOENT':
                        return [];

                    default:
                        throw error;
                }
            }
            else throw error;
        }
    }
    
    /**
      * find the start and end position of each Bucket entry
      */
    public function ranges():Array<BucketItemRange> {
        var si = new Stack(separatorIndices());
        if ( si.empty )
            return [];
        var rl:Array<BucketItemRange> = [];
        inline function r(x,?y) rl.push({x:x, y:y});
        r(0, si.peek());
        while (si.peek(1) != null) {
            r(si.pop() + 1, si.peek());
        }
        //r(si.pop() + 1);
        return rl;
    }

    /**
      * get a ByteArray representing the data for the [index]th entry
      */
    private function get_item_data(index : Int):Null<ByteArray> {
        try {
            var buf:ByteArrayBuffer = new ByteArrayBuffer();
            var fi = input(), ci:Int = 0;
            try {
                var c:Byte;
                while ( true ) {
                    c = fi.readByte();
                    if (c == delimiter) {
                        if (ci == index) {
                            return buf.getByteArray();
                        }
                        ci++;
                    }
                    else if (ci == index) {
                        buf.addByte( c );
                    }
                    else continue;
                }
            }
            catch (e : haxe.io.Eof) {
                if (ci == index) {
                    return buf.getByteArray();
                }
            }
            fi.close();
        }
        catch (err : tannus.node.Error) {
            if (err.code.startsWith('E') && err.syscall != null) {
                switch ( err.code ) {
                    case 'ENOENT':
                        return null;

                    default:
                        throw err;
                }
            }
            else throw err;
        }
        return null;
    }

    /**
      * slap a new hunk of bytes onto the end of the data-store
      */
    private function append_item_data(data : ByteArray):Void {
        var ao = output( true );
        ao.writeByte( delimiter );
        ao.write( data );
        ao.flush();
        ao.close();
    }

    /**
      * get [index] item
      */
    public function get(index : Int):Null<T> {
        var data = get_item_data( index );
        return (data != null ? decode( data ) : null);
    }

    /**
      * add item to the bottom of the bucket
      */
    public function append(item : T):Void {
        append_item_data(encode( item ));
    }

    /**
      * write [items] onto [this] Bucket
      */
    private function write(?items:Array<T>, offset:Int=0, ?len:Int, truncate:Bool=false):Void {
        if (items == null)
            if (_ic != null)
                items = _ic;
            else
                throw 'DaFuq: Nothing to save';
        // [startIndex] specifies the index of the first bucket item to be overwritten
        var fut:Null<ByteArray> = null;
        var rangl:Array<BucketItemRange> = ranges();
        // calculate those parts of the data that will not be overwritten and are not being rewritten either
        if (len == null)
            len = items.length;
        if ((offset + len) != rangl.length && !truncate) {
            fut = _lslice(rangl.slice(offset + len));
        }

        // calculate the total data for all rewritten items
        var total_datas:Array<ByteArray> = items.map.fn(encode(_));
        if (fut != null) total_datas.push( fut );
        
        // create the Output
        var o = output();
        var byteOffset:Int = 0;
        if (offset > 0) {
            byteOffset = (rangl[offset].y + 1);
        }
        // seek to the starting position
        o.seek(byteOffset, SeekBegin);
        for (i in 0...total_datas.length) {
            o.write(total_datas[i]);
            if (i != (total_datas.length - 1))
                o.writeByte( delimiter );
            o.flush();
        }
        o.close();
    }

    /**
      * get data from range
      */
    private function _slice(r : BucketItemRange):ByteArray {
        return _safe(function() return Fs.read(path, r.x, (r.y!=null?(r.y-r.x):(dataLength() - r.x))));
    }

    /**
      * get the entire collective data for a set of ranges
      */
    private function _lslice(ra : Array<BucketItemRange>):Null<ByteArray> {
        if (ra.empty())
            return null;
        return _slice({
            x: ra[0].x,
            y: ra[ra.length - 1].y
        });
    }

    /**
      * wrap a filesystem-action in a safety net
      */
    private function _safe<T>(f : Void->T):Null<T> {
        try {
            return f();
        }
        catch (error : tannus.node.Error) {
            if (error.code == 'ENOENT') 
                return null;
            else throw error;
        }
    }

    /**
      * iterate over all item datas
      */
    public function itemDatas():BucketItemDataIterator<T> {
        return new BucketItemDataIterator( this );
    }

    /**
      * iterate over all items
      */
    public function items():BucketItemIterator<T> {
        return new BucketItemIterator( this );
    }
    public function allItems():Array<T> {
        var res = [];
        for (item in items()) {
            res.push( item );
        }
        return res;
    }

    /**
      * get the total length of the Bucket data
      */
    public inline function dataLength():Int {
        return Fs.stat( path ).size;
    }

/* === Implementation Methods === */

    /**
      * decode a ByteArray into an item
      */
    public function decode(b : ByteArray):T {
        return throw 'Not implemented';
    }

    /**
      * encode an item to a ByteArray
      */
    public function encode(i : T):ByteArray {
        return throw 'Not implemented';
    }

/* === Instance Fields === */

    public var path : Path;
    public var delimiter : Byte;

    // 'cache'd items
    private var _ic : Null<Array<T>> = null;
}

/**
  * iterate over each Bucket item's data
  */
@:access( pman.db.Bucket )
class BucketItemDataIterator<T> {
    private var b : Bucket<T>;
    private var i : Iterator<BucketItemRange>;
    public inline function new(b : Bucket<T>):Void {
        this.b = b;
        this.i = b.ranges().iterator();
    }

    // check if there's another value to be had
    public inline function hasNext():Bool return i.hasNext();

    // get the next value
    public inline function next():ByteArray return b._slice(i.next());
}

class BucketItemIterator<T> {
    private var b : Bucket<T>;
    private var di : BucketItemDataIterator<T>;
    public inline function new(b : Bucket<T>):Void {
        this.b = b;
        this.di = this.b.itemDatas();
    }

    public inline function hasNext():Bool return di.hasNext();
    public inline function next():T return b.decode(di.next());
}

@:structInit
class BucketItemRange {
    public var x : Int;
    @:optional public var y : Int;
}

//typedef BucketItemRange = {
    //x : Int,
    //?y : Int
//};
