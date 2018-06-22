package pman.ds.io;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import pman.ds.Transform.TransformSync as Transform;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class ByteArrayTransform<Target> extends Transform<ByteArray, Target> {

}

class PlainText extends ByteArrayTransform<String> {
    override function encode(b: ByteArray) return b.toString();
    override function decode(s: String) return ByteArray.ofString(s);
}

class Base64 extends ByteArrayTransform<String> {
    override function encode(b: ByteArray) return b.toBase64();
    override function decode(s: String) return ByteArray.fromBase64( s );
}

class HaxeBytes extends ByteArrayTransform<haxe.io.Bytes> {
    override function encode(b: ByteArray) return b.toBytes();
    override function decode(b: haxe.io.Bytes) return ByteArray.fromBytes( b );
}
