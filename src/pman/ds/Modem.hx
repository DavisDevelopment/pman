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

/*
   a class used for managing data going through a Port
*/
class Modem <I, O> {
    /* Constructor Function */
    public function new() {
        //initialize variables
    }

/* === Instance Methods === */

    public function encode(o: O):I throw 'not implemented';
    public function decode(i: I):O throw 'not implemented';

    public function read(?cb: Cb<O>):Promise<O> {
        return _read().transform(i -> decode(i)).toAsync( cb );
    }

    public function write(data:O, ?cb:VoidCb):VoidPromise {
        return _write(encode(data)).toAsync( cb );
    }

    function _read(?cb: Cb<I>):Promise<I> return port.read( cb );
    function _write(i:I, ?cb:VoidCb):VoidPromise return port.write(i, cb);

/* === Computed Instance Fields === */
/* === Instance Fields === */

    var port:Port<I>;
}
