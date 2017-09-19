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

class Query {
    /* Constructor Function */
    public function new(?o : Object):Void {
        this.o = (o != null ? o : new Object({}));
        ops = new Operators();
    }

/* === Operators === */

    public function eq(fieldName:String, value:Dynamic):Query {
        o[fieldName] = value;
        return this;
    }
    public function lt(k:String, v:Dynamic):Query return op(k, fn(_.lt(v)));
    public function lte(k:String, v:Dynamic):Query return op(k, fn(_.lte(v)));
    public function gt(k:String, v:Dynamic):Query return op(k, fn(_.gt(v)));
    public function gte(k:String, v:Dynamic):Query return op(k, fn(_.gte(v)));
    public function has(k:String, v:Dynamic):Query return op(k, fn(_.has(v)));
    public function nhas(k:String, v:Dynamic):Query return op(k, fn(_.nhas(v)));
    public function exists(k:String, v:Bool):Query return op(k, fn(_.exists(v)));
    public function regex(k:String, v:RegEx):Query return op(k, fn(_.regex(v)));
    public function size(k:String, v:Int):Query return op(k, fn(_.size(v)));
    public function elemMatch(k:String, v:Dynamic):Query return op(k, fn(_.elemMatch(v)));
    private function logical(op:Void->(Dynamic->Dynamic), other:EitherType<Query, Query->Query>):Query {
        return new Query(op()([this, qb(other)]));
    }
    public function and(other : EitherType<Query, Query->Query>):Query {
        return logical(fn(ops.and), other);
    }
    public function or(other : EitherType<Query, Query->Query>):Query {
        return logical(fn(ops.or), other);
    }
    public function invert():Query {
        return not( this );
    }


/* === Instance Methods === */

    /**
      * apply an operator
      */
    private function op(fieldName:String, f:Operators->Dynamic):Query {
        o[fieldName] = f( ops );
        return this;
    }

    /**
      * convert to a raw Object
      */
    public inline function toObject():Object {
        return o;
    }

/* === Instance Fields === */

    private var o:Object;

    private static var ops:Operators = {new Operators();};

/* === Static Methods === */

    public static function qb(q : EitherType<Query, Query->Query>):Query {
        if (Reflect.isFunction( q )) {
            return untyped q(new Query());
        }
        else return untyped q;
    }

    public static inline function oqb(q : EitherType<Query, Query->Query>):Object {
        return qb( q ).toObject();
    }

    public static function not(query : EitherType<Query, Query->Query>):Query {
        return new Query(ops.not(qb( query )));
    }

    public static function where<T>(predicate : T->Bool):Query {
        return new Query(ops.where( predicate ));
    }
}

abstract QueryDecl (EitherType<Query, Query->Query>) from EitherType<Query, Query->Query> {
    public inline function new(q : EitherType<Query, Query->Query>) {
        this = q;
    }

    @:to
    public inline function toQuery():Query {
        return Query.qb( this );
    }

    @:to
    public inline function toObject():Object {
        return Query.oqb( this );
    }

    @:to
    public inline function toDynamic():Dynamic {
        return toObject();
    }

    @:from
    public static inline function fromFunc(f : Query->Query):QueryDecl return new QueryDecl( f );
}
