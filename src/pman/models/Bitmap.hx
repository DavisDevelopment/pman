package pman.models;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.graphics.Color;
import tannus.math.IterRange;

import haxe.io.Bytes;
import haxe.io.UInt8Array;

import Slambda.fn;
import tannus.math.TMath.*;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;

abstract Bitmap (BitmapObject) from BitmapObject to BitmapObject {
    /* Constructor Function */
    public inline function new(o) {
        this = o;
    }
}

interface BitmapObject extends pman.models.Image.ImageObject {
    function getData():BitmapData;
}

interface BitmapDataObject {
    var width(default, null): Int;
    var height(default, null): Int;
    
    function get(index: Int): Int;
    function set(index:Int, value:Int):Int;
    function clear():Void;

    //#if (renderer_process || worker)
    //public function paint(c:gryffin.display.Ctx, src:Rect<Float>, dest:Rect<Float>):Void {

    //}
    //#end
}

@:forward
abstract BitmapData (BitmapDataObject) from BitmapDataObject to BitmapDataObject {
    public inline function new(d) {
        this = d;
    }

/* === Instance Methods === */

    @:arrayAccess
    public inline function get(index: Int):Int {
        return this.get( index );
    }

    @:arrayAccess
    public inline function set(index:Int, value:Int):Int {
        return this.set(index, value);
    }
}

class BitmapDataBase {
    /* Constructor Function */
    //public function new(w:Int, h:Int):Void {
        //this.width = w;
        //this.height = h;
    //}

/* === Instance Methods === */

/* === Instance Fields === */

    public var width(default, null): Int;
    public var height(default, null): Int;
}

class ValuesBitmapData extends BitmapDataBase implements BitmapDataObject {
    /* Constructor Function */
    public function new(w:Int, h:Int, d:UInt8Array):Void {
        width = w;
        height = h;
        data = d;
    }

/* === Instance Methods === */

    public inline function get(i: Int):Int {
        return data[i];
    }

    public inline function set(i:Int, v:Int):Int {
        return data[i] = v;
    }

    public function clear() {
        data = UInt8Array.fromBytes(Bytes.alloc(data.length));
    }


/* === Instance Fields === */

    public var data(default, null): UInt8Array;
}

class LinkedBitmapData extends BitmapDataBase implements BitmapDataObject {
    /* Constructor Function */
    public function new(x:Int, y:Int, w:Int, h:Int, d:BitmapData):Void {
        width = w;
        height = h;
        this.x = x;
        this.y = y;
        data = d;
    }

/* === Instance Methods === */

    /**
      get a UInt8 value
     **/
    public inline function get(i: Int):Int {
        // get [i]'s (x, y) offset in [this] data
        var p = pos(i, width);

        // recalculate that offset relative to [this]'s x, y values
        p = [p[0] + x, p[1] + y];

        // recalculate [i] relative to [data]
        i = offset(p[0], p[1], data.width);

        return data[i];
    }

    /**
      assign a UInt8 value
     **/
    public inline function set(i:Int, v:Int):Int {
        // get [i]'s (x, y) offset in [this] data
        var p = pos(i, width);

        // recalculate that offset relative to [this]'s x, y values
        p = [p[0] + x, p[1] + y];

        // recalculate [i] relative to [data]
        i = offset(p[0], p[1], data.width);
        return data[i] = v;
    }

    /**
      erase [this]
     **/
    public function clear() {
        for (row in y...height) {
            for (col in x...width) {
                var i = offset(col, row, width);

                set(i + 0, 0);
                set(i + 1, 0);
                set(i + 2, 0);
                set(i + 3, 0);
            }
        }
    }

    static inline function pos(i:Int, w:Int):Array<Int> {
        return [floor(i % w), floor(i / w)];
    }

    static inline function offset(x:Int, y:Int, w:Int):Int {
        return x + w * y;
    }

/* === Instance Fields === */

    public var data(default, null): BitmapData;
    public var x(default, null): Int;
    public var y(default, null): Int;
}
