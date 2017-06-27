package pman.db;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import haxe.Constraints.Function;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Modem <I, O> {
    public function new():Void {
        _d = null;
    }

/* === Instance Methods === */

    public function decode(i : I):O return throw 'not implemented';
    public function encode(o : O):I return throw 'not implemented';

    public function read():O {
        _d = decode(_read());
        return _d;
    }

    public function write(?o : O):Void {
        if (o == null)
            o = _d;
        if (o == null)
            throw 'buttsex a goldfish';
        _write(encode( o ));
    }

    public function edit(editor : Function):Void {
        var newd:Null<O> = editor(read());
        if (newd == null)
            newd = _d;
        write( newd );
    }

    private function _read():I return port.read();
    private function _write(i : I):Void port.write( i );

/* === Instance Fields === */

    public var port: Port<I>;
    private var _d : Null<O>;
}

class BinaryFilePort extends Port<ByteArray> {
    public var path : Path;
    public function new(path : Path):Void {
        super();
        this.path = path;
    }
    override function read():ByteArray return Fs.read( path );
    override function write(o : ByteArray):Void Fs.write(path, o);
}

@:expose('TextFilePort')
class TextFilePort extends Port<String> {
    public var path : Path;
    public function new(path : Path):Void {
        super();
        this.path = path;
    }
    override function read():String return Fs.read( path );
    override function write(o : String):Void Fs.write(path, o);
}

@:expose('JsonModem')
class JsonModem<T> extends Modem<String, T> {
    override function decode(s : String):T return untyped Json.parse( s );
    override function encode(o : T):String return Json.stringify(o, null, '');
}

class HxSerializationModem<T> extends Modem<String, T> {
    override function decode(s : String):T return Unserializer.run( s );
    override function encode(o : T):String {
        Serializer.USE_CACHE = true;
        return Serializer.run( o );
    }
}
