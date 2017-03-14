package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.sys.*;

import ida.*;

import pman.core.*;
import pman.media.*;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class ConfigInfo extends StoredModel {
    /* Constructor Function */
    public function new(db : PManDatabase):Void {
        super();

        this.db = db;
        storage = new CiStorage();
    }

/* === Computed Instance Fields === */

    // the directory that was most recently opened
    public var lastDirectory(get, set):Null<String>;
    private inline function get_lastDirectory():Null<String> return get('lastDirectory');
    private function set_lastDirectory(v : Null<String>):Null<String> return set('lastDirectory', v);

/* === Instance Fields === */

    public var db : PManDatabase;
}

// custom Storage class for ConfigInfo
private class CiStorage extends WebStorage {
    public function new():Void {
        super(js.Browser.getLocalStorage());
    }

    override function map_key(key : String):String {
        return 'config:$key';
    }
    override function encode(value:Dynamic, ?key:String):String {
        return Serializer.run( value );
    }
    override function decode(str:String, ?key:String):Dynamic {
        return Unserializer.run( str );
    }
}
