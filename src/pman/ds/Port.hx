package pman.ds;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class Port<T> {
    /* Constructor Function */
    public function new() { }

    public function read(?callback: Cb<T>):Promise<T> throw 'not implemented';
    public function write(data:T, ?callback:VoidCb):VoidPromise throw 'not implemented';

    // transform [this] Port
    public function map<O>(i:T->O, o:O->T):Port<O> {
        return cast new MappedPort(this, {
            i: i,
            o: o
        });
    }
}

/*
   typedef describing an Object used to represent the transformation of data through a Port
*/
typedef PortMapper<TIn, TOut> = {
    i: TIn -> TOut,
    o: TOut -> TIn
};

/**
  purpose of class
 **/
class MappedPort<I,O> extends Port<O> {
    /* Constructor Function */
    public function new(i:Port<I>, m:PortMapper<I,O>) {
        super();

        this.ip = i;
        this.m = m;
    }

/* === Instance Methods === */

    // read transformed data from [ip]
    override function read(?cb: Cb<O>):Promise<O> {
        return ip.read().transform(input -> m.i(input)).toAsync(cb);
    }

    // write transformed data to [ip]
    override function write(o:O, ?cb:VoidCb):VoidPromise {
        return ip.write(m.o(o)).toAsync( cb );
    }

/* === Instance Fields === */

    var ip: Port<I>;
    var m: PortMapper<I, O>;
}