package pman.db;

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

class Port<T> {
    //private var _d : Null<T>;
    public function new():Void {
        //_d = null;
    }
    public function read():T return throw 'not implemented';
    public function write(d : T):Void throw 'not implemented';
    public function map<O>(i:T -> O, o:O -> T):Port<O> {
        return cast new MappedPort(this, {i:i, o:o});
    }
}

typedef PortMapper<TIn,TOut> = {i:TIn->TOut,o:TOut->TIn};

class MappedPort <I, O> extends Port<O> {
    private var ip : Port<I>;
    private var m : PortMapper<I,O>;
    public function new(i:Port<I>, m:PortMapper<I,O>):Void {
        super();
        ip = i;
        this.m = m;
    }
    override function read():O return m.i(ip.read());
    override function write(o : O):Void ip.write(m.o( o ));
}
