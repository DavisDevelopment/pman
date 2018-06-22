package pman.ds;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;
//import tannus.async.Result;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;
import haxe.ds.Option;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

import pman.ds.Port;
import pman.ds.Transform;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using tannus.async.Result;

/*
   a class used for managing data going through a Port
*/
class Modem <I, O> {
    /* Constructor Function */
    public function new(?port:Port<I>, ?transform:TransformSync<O, I>):Void {
        this.port = port;
        this.transform = transform;

        _rp_ = Option.None;
        _wp_ = Option.None;
    }

/* === Instance Methods === */

    public function encode(o: O):I {
        return transform.encode( o );
    }

    public function decode(i: I):O {
        return transform.decode( i );
    }

    public function read(?cb: Cb<O>):Promise<O> {
        //return _read().transform(i -> decode(i)).toAsync( cb );
        switch _rp_ {
            case null, None:
                var prom:Promise<O>;
                _rp_ = Some(prom = _read().transform.fn(decode(_)).toAsync(cb));
                return prom.then(
                    function(out: O) {
                        _rp_ = None;
                    },
                    function(error) {
                        global.console.error(error);
                    }
                );

            case Some(prom):
                return prom.transform(x -> x);
        }
    }

    public function write(data:O, ?cb:VoidCb):VoidPromise {
        switch _wp_ {
            case null, None:
                var vp;
                _wp_ = Some(vp = _write(encode(data)).toAsync( cb ));
                return vp.then(
                    function() {
                        _wp_ = None;
                    },
                    function(error) {
                        global.console.error(error);
                    }
                );

            case Some(prom):
                return new VoidPromise(function(accept, reject) {
                    prom.always(function() {
                        //accept(cast write(data, cb));
                        write(data).then(accept, reject);
                    });
                }).toAsync(cb);
        }
    }

    function _read(?cb: Cb<I>):Promise<I> return port.read( cb );
    function _write(i:I, ?cb:VoidCb):VoidPromise return port.write(i, cb);

    public inline function isReading():Bool {
        return _rp_.match(Some(_));
    }

    public inline function isWriting():Bool {
        return _wp_.match(Some(_));
    }

    /**
      create (in a functional style) a new Modem instance
     **/
    public static function create<I, O>(read:Void->Promise<I>, write:I->VoidPromise, encode:I->O, decode:O->I):Modem<I, O> {
        return new FunctionalModem(read, write, encode, decode);
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var port: Port<I>;
    public var transform: TransformSync<O, I>;

    var _rp_: Option<Promise<O>>;
    var _wp_: Option<VoidPromise>;
}

class FunctionalModem<I, O> extends Modem<I, O> {
    public function new(read:Void->Promise<I>, write:I->VoidPromise, encode:I->O, decode:O->I) {
        super(cast new FunctionalPort(read, write), cast new FuncTransformSync(encode, decode));
    }
}

/**
  enum for how Modem should handle consecutive calls to 'read' and 'write', while the previous one has yet to complete
 **/
enum ModemMultiType {
    /**
      simply silently ignore the excess call
     **/
    MMTIgnore;

    /**
      chain consecutive calls to that each one is run after the previous one completes
     **/
    MMTChain;
}
