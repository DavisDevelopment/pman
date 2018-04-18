package pman.sys;

import tannus.ds.*;
import tannus.ds.dict.DictKey;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.storage.fs.async.EntryType;
import edis.storage.fs.async.EntryType.WrappedEntryType as Wet;
import edis.Globals.*;

import pman.sys.FSWFilter;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

import Slambda.fn;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;

enum ValueExtractor<T> {
    VConst(value: T):ValueExtractor<T>;
    VProperty(name:Value<Stringoid>):ValueExtractor<T>;
    VArrayAccess<K:DictKey>(key:K):ValueExtractor<T>;

    VBinOp<L, R>(op: ValueBinaryOperator<L, R, T>);

/* === Type-Specific Values === */

    VPromiseResolution<V>():ValueExtractor<Result<V, Dynamic>>;
    VRegExMatch(re: RegEx):ValueExtractor<Bool>;
}

enum ValueBinaryOperator<Left, Right, Out> {
    OpEq<T>(x:ValueExtractor<T>):ValueBinaryOperator<T, T, Bool>;
    OpNeq<T>(x:ValueExtractor<T>):ValueBinaryOperator<T, T, Bool>;
}

abstract Stringoid (Stringable) from Stringable to Stringable {
    public inline function new(x: Stringable) {
        this = x;
    }

    @:to
    public inline function toString():String {
        return Std.string( this );
    }
}

private typedef Stringable = EitherType<String, {toString: Void->String}>;
typedef Value<T> = pman.sys.ValueExtractor<T>;
