package pman.ds.io;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;

import pman.ds.Transform.TransformSync as Transform;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.ds.AnonTools;
using tannus.FunctionTools;

class SerialTransform<T> extends Transform<T, String> {
    public dynamic function afterSerialization(s: String):String {
        return s;
    }

    public dynamic function beforeDeserialization(s: String):String {
        return s;
    }
}

class JSON<T> extends SerialTransform<T> {
    public var prettyPrint:Bool = false;
    public var space:Null<String> = '  ';

    override function encode(x: T):String {
        return afterSerialization(Json.stringify(x, null, prettyPrint ? space : null));
    }

    override function decode(data: String):T {
        return Json.parse(beforeDeserialization( data ));
    }
}

class HxSerialization<T> extends SerialTransform<T> {
    override function encode(x: T):String {
        return afterSerialization(serialize(function(writer) {
            //inline function put(x: Dynamic) writer.serialize( x );
            writer.serialize( x );
        })
        .toString());
    }

    override function decode(s: String):T {
        s = beforeDeserialization( s );
        return cast unserializer( s ).unserialize();
    }

    function serialize(f: Serializer->Void):Serializer {
        var s:Serializer = new Serializer();
        s.useCache = true;
        s.useEnumIndex = false;
        f( s );
        return s;
    }

    function unserializer(data:String, ?setup:Unserializer->Void):Unserializer {
        var us:Unserializer = new Unserializer( data );
        if (setup != null)
            setup( us );
        return us;
    }
}
