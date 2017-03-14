package pman.db;

import tannus.ds.*;
import tannus.io.*;
import tannus.mvc.Requirements;

import electron.Tools.defer;

import js.html.Storage in NStorage;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using Slambda;

class WebStorage extends Storage {
    /* Constructor Function */
    public function new(s : NStorage):Void {
        super();

        this.s = s;
    }

/* === Instance Methods === */

    // get a value
    override function get<T>(key : String):Null<T> {
        key = map_key( key );
        var str_val:Null<String> = sget( key );
        if (str_val != null) {
            return decode(str_val, key);
        }
        else {
            return null;
        }
    }

    // set a value
    override function set<T>(key:String, value:T):T {
        key = map_key( key );
        sset(key, encode(value, key));
        return value;
    }

    // remove a property from [this]
    override function remove(key : String):Bool {
        key = map_key( key );
        var has = exists( key );
        s.removeItem( key );
        return has;
    }

    // check for presence of a property
    override function exists(key : String):Bool {
        return (keylist().has( key ));
    }

    // iterate over keys
    override function keys():Array<String> {
        return keylist();
    }

    override function fetch(done : Void->Void):Void {
        super.fetch(done);
    }
    override function push(done : Void->Void):Void {
        super.push( done );
    }

    /**
      * transform property keys
      */
    private function map_key(key : String):String {
        return key;
    }

    /**
      * parse an encoded String into a value
      */
    private function decode(s:String, ?key:String):Dynamic {
        return haxe.Json.parse( s );
    }

    /**
      * convert the given value to a String (default method is JSON stringification)
      */
    private function encode(v:Dynamic, ?key:String):String {
        return haxe.Json.stringify( v );
    }

    // get a value as a String
    private inline function sget(k:String):Null<String> return s.getItem(k);

    // set a String value
    private inline function sset(k:String, v:String):Void s.setItem(k, v);

    /**
      * iterate over all the keys of [s]
      */
    private function nskeys():Iterator<String> {
        return (0...s.length).map.fn(s.key(_));
    }

    /**
      * get the keys, but as an Array
      */
    private function keylist():Array<String> {
        return cast (untyped __js__('Object.keys'))( s );
    }

/* === Instance Fields === */

    private var s : NStorage;
}
