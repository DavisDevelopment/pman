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
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.async.VoidAsyncs;

class Operators {
    /* Constructor Function */
    public function new():Void {
        //TODO
    }

/* === Instance Methods === */

    /**
      * create and return an operator
      */
    public function op(name:String, operand:Dynamic):Dynamic {
        return _buildObject(function(o : Object) {
            o[opname(name)] = sanitize( operand );
        });
    }

/* === Query Operators === */

    public function lt(value : Dynamic):Dynamic return op('lt', value);
    public function lte(value : Dynamic):Dynamic return op('lte', value);
    public function gt(value : Dynamic):Dynamic return op('gt', value);
    public function gte(value : Dynamic):Dynamic return op('gte', value);
    public function has(value : Dynamic):Dynamic return op('in', value);
    public function nhas(value : Dynamic):Dynamic return op('nin', value);
    public function exists(doesExist:Bool=true):Dynamic return op('exists', doesExist);
    public function regex(pattern:RegEx):Dynamic return op('regex', (untyped pattern).r);
    public function size(size:Int):Dynamic return op('size', size);
    public function elemMatch(query:Dynamic):Dynamic return op('elemMatch', query);
    public function or(queries:Array<Dynamic>):Dynamic return op('or', queries);
    public function and(queries:Array<Dynamic>):Dynamic return op('and', queries);
    public function not(query:Dynamic):Dynamic return op('not', query);
    public function where(predicate:Dynamic->Bool):Dynamic {
        return op('where', function() {
            return predicate( js.Lib.nativeThis );
        });
    }

/* === Update Operators === */

    public function increment(data : Dynamic):Dynamic return op('inc', data);
    public inline function inc(d:Dynamic):Dynamic return increment( d );
    public function set(d : Dynamic):Dynamic return op('set', d);
    public function unset(d : Dynamic):Dynamic return op('unset', d);
    public function push(d : Dynamic):Dynamic return op('push', d);
    public function pop(d : Dynamic):Dynamic return op('pop', d);
    public function addToSet(d : Dynamic):Dynamic return op('addToSet', d);
    public function pull(d : Dynamic):Dynamic return op('pull', d);
    public function min(d : Dynamic):Dynamic return op('min', d);
    public function max(d : Dynamic):Dynamic return op('max', d);

/* === Utility Methods === */

    /**
      * sanitize the given object
      */
    private function sanitize(v : Dynamic):Dynamic {
        if ((v is Query)) {
            return cast(v, Query).toObject();
        }
        else {
            return v;
        }
    }

    /**
      * utility method to construct an Object
      */
    private function _buildObject(f : Object->Void):Object {
        var o:Object = {};
        f( o );
        return o;
    }
    private inline function _bo(f : Object->Void):Object return _buildObject( f );
    
    /**
      * get the key name for the given operator
      */
    private function opname(name:String):String {
        return '$$$name';
    }
}
