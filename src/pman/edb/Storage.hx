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

class Storage {
    /* Constructor Function */
    public function new():Void {
        modem = new JsonModem();
        state = null;
    }

/* === Instance Methods === */

    public function pull():Void {
        state = modem.read();
    }

    public function push():Void {
        if (state != null) {
            modem.write( state );
        }
    }

    public function purge():Void {
        state = null;
    }

    public function get<T>(name : String):Maybe<T> {
        pull();
        return state[name];
    }

    public function set<T>(name:String, value:T):T {
        pull();
        return (state[name] = value);
    }

    public function remove(name : String):Bool {
        pull();
        state.remove( name );
    }

    public function keys():Iterator<String> {
        pull();
        return state.keys.iterator();
    }

    public function exists(name : String):Bool {
        pull();
        return state.exists( name );
    }

/* === Computed Instance Fields === */

    public var port(get, set):Port<String>;
    private inline function get_port() return modem.port;
    private inline function set_port(v) return (modem.port = v);

/* === Instance Fields === */

    public var modem : Modem<String, Object>;

    private var state : Null<Object>;
}
