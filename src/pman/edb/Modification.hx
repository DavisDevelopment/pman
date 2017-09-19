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

    public function set(data:Dynamic):Modification return op('set', data);
    public function increment(data:Dynamic):Modification return op('inc', data);
    public function unset(data:Dynamic):Modification return op('unset', data);
    public function push(d:Dynamic):Modification return op('push', d);
    public function pop(d:Dynamic):Modification return op('pop', d);
    public function addToSet(d:Dynamic):Modification return op('addToSet', d);
    public function pull(d:Dynamic):Modification return op('pull', d);
    public function min(d:Dynamic):Modification return op('min', d);
    public function max(d:Dynamic):Modification return op('max', d);

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
