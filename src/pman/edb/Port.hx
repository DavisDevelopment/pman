package pman.edb;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import haxe.Constraints.Function;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/*
   a class used to represent a single medium of data input/output
*/
class Port<T> {
    public function new():Void {
        //
    }

    // read data from [this] Port
    public function read():T return throw 'not implemented';

    // write data to [this] Port
    public function write(d : T):Void throw 'not implemented';

    // transform [this] Port
    public function map<O>(i:T -> O, o:O -> T):Port<O> {
        return cast new MappedPort(this, {i:i, o:o});
    }
}

/*
   typedef describing an Object used to represent the transformation of data through a Port
*/
typedef PortMapper<TIn, TOut> = {
    i: TIn -> TOut,
    o: TOut -> TIn
};

/*
   a class used for data transformations on a Port
*/
class MappedPort <I, O> extends Port<O> {
    /* Constructor Function */
    public function new(i:Port<I>, m:PortMapper<I,O>):Void {
        super();

        ip = i;
        this.m = m;
    }

    // read transformed data from [ip]
    override function read():O return m.i(ip.read());

    // write transformed data to [ip]
    override function write(o : O):Void ip.write(m.o( o ));

    // the input port
    private var ip : Port<I>;

    // the mapper object
    private var m : PortMapper<I,O>;
}
