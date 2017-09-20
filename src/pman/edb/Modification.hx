package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;

import nedb.DataStore;

import Slambda.fn;
import tannus.math.TMath.*;
import haxe.extern.EitherType;
import haxe.Constraints.Function;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.async.VoidAsyncs;
using tannus.html.JSTools;

class Modification {
    /* Constructor Function */
    public function new(?o : Object):Void {
        this.o = (o != null ? o : {});
    }

/* === Operators === */

    public function set(index:String, value:Dynamic):Modification {
        return _set(_bokv(index, value));
    }

    public function inc(index:String, value:Int):Modification {
        return _increment(_bokv(index, value));
    }

    public function unset(index:String, value:Dynamic):Modification {
        return _unset(_bokv(index, value));
    }

    public function push(index:String, value:Dynamic):Modification {
        return _push(_bokv(index, value));
    }

    public function pop(index:String, value:Dynamic):Modification {
        return _pop(_bokv(index, value));
    }

    public function addToSet(index:String, value:Dynamic):Modification {
        return _addToSet(_bokv(index, value));
    }

    public function pull(index:String, value:Int=1):Modification {
        if (value < 0)
            value = -1;
        else value = 1;
        return _pull(_bokv(index, value));
    }

    public function min(index:String, value:Dynamic):Modification {
        return _min(_bokv(index, value));
    }

    public function max(index:String, value:Dynamic):Modification {
        return _max(_bokv(index, value));
    }


    public function _set(data:Dynamic):Modification return op('set', data);
    public function _increment(data:Dynamic):Modification return op('inc', data);
    public function _unset(data:Dynamic):Modification return op('unset', data);
    public function _push(d:Dynamic):Modification return op('push', d);
    public function _pop(d:Dynamic):Modification return op('pop', d);
    public function _addToSet(d:Dynamic):Modification return op('addToSet', d);
    public function _pull(d:Dynamic):Modification return op('pull', d);
    public function _min(d:Dynamic):Modification return op('min', d);
    public function _max(d:Dynamic):Modification return op('max', d);

/* === Instance Methods === */

    /**
      * convert [this] to a raw Object
      */
    public inline function toObject():Object {
        return o;
    }

    /**
      * add an operator
      */
    private function op(name:String, operand:Dynamic):Modification {
        o[opname(name)] = sanitize( operand );
        return this;
    }

    /**
      * sanitize an Object
      */
    private function sanitize(v : Dynamic):Dynamic {
        if ((v is Modification)) {
            return cast(v, Modification).toObject();
        }
        else if ((v is Query)) {
            return cast(v, Query).toObject();
        }
        else {
            return v;
        }
    }

    /**
      * compute the key for an operator
      */
    private inline function opname(name:String):String return '$$$name';

    /**
      * utility method to construct an Object
      */
    private function _buildObject(f : Object->Void):Object {
        var o:Object = {};
        f( o );
        return o;
    }
    private inline function _bo(f : Object->Void):Object return _buildObject( f );
    private function _bokv(k:String, v:Dynamic):Object {
        return _buildObject(function(o) {
            o[k] = v;
        });
    }
 

/* === Instance Fields === */

    private var o : Object;

/* === Statics === */

    public static function mb(m : EitherType<Modification, Function>):Modification {
        if (Reflect.isFunction( m )) {
            var mod:Modification = new Modification();
            var result:Null<Dynamic> = untyped m(mod);
            if ((result is Modification)) {
                return cast result;
            }
            else return mod;
        }
        else return cast m;
    }

    private static var ops:Operators = {new Operators();};
}

abstract Mod (EitherType<Modification, Function>) from EitherType<Modification, Function> {
    public inline function new(m : EitherType<Modification, Function>) {
        this = m;
    }

    @:to
    public inline function toMod():Modification return Modification.mb( this );

    @:to
    public inline function toObject():Object return toMod().toObject();

    @:to
    public inline function toDynamic():Dynamic return toObject();

    @:from
    public static inline function fromFunction(f : Function):Mod return new Mod( f );
}
