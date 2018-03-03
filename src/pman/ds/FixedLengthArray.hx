package pman.ds;

import Std.*;
import tannus.math.TMath.*;
#if !eval
import edis.Globals.*;
#end
import Slambda.fn;

using tannus.FunctionTools;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.IteratorTools;
using tannus.math.TMath;
#if !eval
using tannus.html.JSTools;
#end

@:expose
class CFixedLengthArray<T> {
    /* Constructor Function */
    public function new(len:Int, ?fill:T) {
        this.length = len;
        for (index in 0...len) {
            nativeArraySet(index, fill);
        }
        untyped __js__('Object.preventExtensions({0})', this);
    }

/* === Instance Methods === */

    public inline function get(index: Int):Null<T> {
        return nativeArrayGet( index );
    }

    public inline function set(index:Int, value:T):Null<T> {
        return nativeArraySet(index, value);
    }

    public inline function hasIndex(i: Int):Bool return i.inRange(0, length);
    public inline function exists(i: Int):Bool return (hasIndex( i ) && get( i ) != null);

    public function indices():IntIterator return (0...length);
    public function iterator():Iterator<T> {
        return indices().map(i -> get( i ));
    }

    /**
      * write data from [a] onto [this]
      */
    public function putArray(a:Array<T>, start:Int=0):FixedLengthArray<T> {
        for (i in indices()) {
            set(i+start, a[i]);
        }
        return this;
    }

    /**
      * write data from [src] onto [this]
      */
    public function blit(src:FixedLengthArray<T>, offset:Int=0, start:Int=0, ?end:Int):FixedLengthArray<T> {
        if (end == null) 
            end = src.length;
        if (!(offset.inRange(0, length) && start.inRange(0, src.length) && end.inRange(0, src.length)))
            throw 'invalid numbers; u stoopid';
        for (i in (0...(end - start))) {
            set(offset+i, src.get(start+i));
        }
        return this;
    }

    /**
      * create a shallow copy of [this] Array
      */
    public function copy():FixedLengthArray<T> {
        return (untyped __js__('Object.assign'))(new CFixedLengthArray( length ), this);
    }

    /**
      * create and return the concatenation of [this] and [other]
      */
    public function concat(other: FixedLengthArray<T>):FixedLengthArray<T> {
        var res = new FixedLengthArray(length + other.length);
        res.blit(this, 0, 0, length);
        res.blit(other, length, 0, other.length);
        return res;
    }

    /**
      * attempt to determine the index of [x]
      */
    public function indexOf(x: T):Int {
        for (index in indices()) {
            if (get(index) == x) {
                return index;
            }
        }
        return -1;
    }

    public function lastIndexOf(x:T, fromIndex:Int=0):Int {
        var i = length;
        while (--i >= fromIndex)
            if (get(i) == x)
                return i;
        return -1;
    }

    /**
      * REDUCE operation
      */
    public function reduce<TAcc>(f:TAcc->T->TAcc, acc:TAcc):TAcc {
        for (x in this) {
            acc = f(acc, x);
        }
        return acc;
    }

    public function reducei<TAcc>(f:TAcc->T->Int->TAcc, acc:TAcc):TAcc {
        for (index in indices()) {
            acc = f(acc, get(index), index);
        }
        return acc;
    }

    public function reduceRight<TAcc>(f:TAcc->T->TAcc, acc:TAcc):TAcc {
        var index:Int = length;
        while (--index >= 0)
            acc = f(acc, get(index));
        return acc;
    }

    /**
      * create and return a new FixedLengthArray made out of the items in [this] FixedLengthArray<T> for which [f] returned 'true'
      */
    public function filter(f: T->Bool):FixedLengthArray<T> {
        return fromArray([for (x in this) {
            if (f( x ))
                x;
        }]);
    }

    /**
      * 'map' operation
      */
    public function map<TOut>(f: T->TOut):FixedLengthArray<TOut> {
        return reducei(function(out:FixedLengthArray<TOut>, x:T, i:Int) {
            out.set(i, f(x));
            return out;
        }, alloc( length ));
    }

    /**
      * reverse the order of the elements in [this]
      */
    public function reverse():Void {
        var i:Int = 0;
        while (i < int(length / 2)) {
            var tmp = get( i );
            set(i, get(length - i - 1));
            set((length - i - 1), tmp);
            ++i;
        }
    }

    /**
      * a slice operation
      */
    public function slice(pos:Int, ?end:Int):FixedLengthArray<T> {
        if (end == null || end > length) {
            end = length;
        }
        else if (end < 0) {
            end = (length + end).max( 0 );
        }
        if (pos < 0) {
            pos = (length + pos).max( 0 );
        }
        if (pos > length || end <= pos) {
            return new FixedLengthArray(0);
        }
        var res:FixedLengthArray<T> = new FixedLengthArray(end - pos);
        res.blit(this, pos);
        return res;
    }

/* === Static Methods === */

    public static function fromArray<T>(a: Array<T>):FixedLengthArray<T> {
        return alloc(a.length).putArray( a );
    }

    public static function fromVector<T>(v: haxe.ds.Vector<T>):FixedLengthArray<T> {
        return fromArray(v.toArray());
    }

    public static function fromIterable<T>(i: Iterable<T>):FixedLengthArray<T> {
        return fromArray(i.array());
    }

    public static function alloc<T>(size:Int, ?fill:T):FixedLengthArray<T> {
        return new FixedLengthArray(size, fill);
    }

/* === Instance Fields === */

    public var length(default, null): Int;

}

@:forward
abstract FixedLengthArray<T> (CFixedLengthArray<T>) from CFixedLengthArray<T> to CFixedLengthArray<T> {
    public inline function new(size:Int, ?fill:T) {
        this = new CFixedLengthArray(size, fill);
    }

    @:arrayAccess
    public inline function get(i: Int):Null<T> return this.get( i );

    @:arrayAccess
    public inline function set(i:Int, v:T):Null<T> return this.set(i, v);

    public static inline function alloc<T>(size:Int, ?fill:T):FixedLengthArray<T> return CFixedLengthArray.alloc(size, fill);
}
