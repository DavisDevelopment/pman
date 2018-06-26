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

class Transform<From, To> implements ITransform<From, To> {
    public function encode(chunk:From, callback:Cb<To>) {
        callback('Not implemented', null);
    }

    public function decode(chunk:To, callback:Cb<From>) {
        callback('Not implemented', null);
    }

    public function compose<T>(t:ITransform<To, T>):ITransform<From, T> {
        return cast FuncTransform.create({
            encode: asynCompose(encode, t.encode),
            decode: asynCompose(t.decode, decode)
        });
    }

    public function flip():ITransform<To, From> {
        return cast new FuncTransform(decode.bind(_, _), encode.bind(_, _));
    }

    inline function cbv<T,Prom:Promise<T>>(promise:Prom, ?cb:Cb<T>):Prom {
        cb = cb.nn();
        return cast promise.then(cb.yield(), cb.raise());
    }

    static function promCompose<A,B,C>(left:A->Promise<B>, right:B->Promise<C>):A->Promise<C> {
        return (function(a: A) {
            return left(a).transform(b -> right(b));
        });
    }

    static function asynCompose<A,B,C>(left:A->Cb<B>->Void, right:B->Cb<C>->Void):A->Cb<C>->Void {
        return (function(a:A, callback:Cb<C>) {
            left.bind(a,_)
                .toPromise()
                .transform(function(b: B) {
                    return (right.bind(b, _).toPromise());
                })
            .toAsync(callback);
        });
    }
}

class FuncTransform<From, To> extends Transform<From, To> {
    public function new(e:From->Cb<To>->Void, d:To->Cb<From>->Void) {
        _encode = e;
        _decode = d;
    }

    override function encode(d, f) _encode(d, f);
    override function decode(d, f) _decode(d, f);

    dynamic function _encode(chunk:From, cb:Cb<To>) null;
    dynamic function _decode(chunk:To, cb:Cb<From>) null;

    public static function create<From,To>(spec: {encode:From->Cb<To>->Void, decode:To->Cb<From>->Void}):FuncTransform<From,To> {
        return new FuncTransform(spec.encode, spec.decode);
    }
    public static function buildFrom<A,B>(ts:ITransform<A,B>):FuncTransform<A, B> {
        return new FuncTransform(ts.encode.bind(_, _), ts.decode.bind(_, _));
    }
}

class TransformSync<From, To> implements ITransformSync<From, To> {
    public function new() {
        //
    }

    public function encode(chunk: From):To {
        throw 'Not implemented';
    }

    public function decode(chunk: To):From {
        throw 'Not implemented';
    }

    public function compose<T>(t: ITransformSync<To, T>):ITransformSync<From, T> {
        return cast new FuncTransformSync(t.encode.compose(encode), decode.compose(t.decode));
    }

    public function flip():ITransformSync<To, From> {
        return cast FuncTransformSync.create({
            encode: decode.bind(_),
            decode: encode.bind(_)
        });
    }

    public function toAsync():ITransform<From,To> {
        return cast new FuncTransform(asyncify(encode), asyncify(decode));
    }

    public static inline function asyncify<A, B>(f: A -> B):A -> Cb<B> -> Void {
        return ((a:A, cb:Cb<B>) -> cb(null, f(a)));
    }

    public static inline function make<X, Y>(e:X->Y, d:Y->X):TransformSync<X, Y> {
        return cast new FuncTransformSync(e, d);
    }

    public static inline function from<X,Y>(ts: ITransformSync<X,Y>):TransformSync<X, Y> {
        return make(ts.encode, ts.decode);
    }

    public static inline function create<X,Y>(o: {encode:X->Y, decode:Y->X}):TransformSync<X,Y> {
        return make(o.encode, o.decode);
    }
}

class FuncTransformSync<From, To> extends TransformSync<From, To> {
    public function new(enc:From->To, dec:To->From) {
        super();

        _encode = enc;
        _decode = dec;
    }

    dynamic function _encode(d:From):To { throw null; }
    dynamic function _decode(d:To):From { throw null; }
    override function encode(d) return _encode(d);
    override function decode(d) return _decode(d);

    public static function create<From,To>(spec:{encode:From->To,decode:To->From}):FuncTransformSync<From,To> {
        return new FuncTransformSync(spec.encode, spec.decode);
    }

    public static function buildFrom<A, B>(ts: ITransformSync<A,B>):FuncTransformSync<A, B> {
        return new FuncTransformSync((a -> ts.encode(a)), (b -> ts.decode(b)));
    }
}

interface IEncoderSync <From, To> {
    function encode(output: From):To;
}

interface IEncoder<From, To> {
    function encode(output:From, callback:Cb<To>):Void;
}

interface IDecoderSync <From, To> {
    function decode(input: From):To;
}

interface IDecoder<From, To> {
    function decode(input:From, callback:Cb<To>):Void;
}

interface ITransformSync <From, To> extends IEncoderSync<From, To> extends IDecoderSync<To, From> {
    function compose<T>(ts: ITransformSync<To, T>):ITransformSync<From, T>;
    function flip():ITransformSync<To, From>;
    function toAsync():ITransform<From, To>;
}

interface ITransform<From, To> extends IEncoder<From, To> extends IDecoder<To, From> {
    function compose<T>(ts:ITransform<To, T>):ITransform<From, T>;
    function flip():ITransform<To, From>;
}
