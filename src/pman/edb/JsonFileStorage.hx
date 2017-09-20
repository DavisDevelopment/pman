package pman.edb;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import haxe.Constraints.Function;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;

import pman.edb.Modem;
import pman.edb.Port;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class JsonFileStorage extends Storage {
    public function new(path : Path):Void {
        super();

        this.path = path;

        this.modem = new JsonModem();
        this.port = new TextFilePort( path );
    }

    public var path : Path;
}
