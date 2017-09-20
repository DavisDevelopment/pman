package pman.edb;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import haxe.Constraints.Function;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;
import haxe.rtti.Meta;

import pman.edb.Modem;
import pman.edb.Port;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

class Storage {
    /* Constructor Function */
    public function new():Void {
        modem = new JsonModem();
        state = null;

        __bindMeta();
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
        _validate();
        return state[name];
    }

    public function set<T>(name:String, value:T):T {
        _validate();
        return (state[name] = value);
    }

    public function remove(name : String):Bool {
        _validate();
        var res = state.exists( name );
        state.remove( name );
        return res;
    }

    public function keys():Iterator<String> {
        _validate();
        return state.keys.iterator();
    }

    public function exists(name : String):Bool {
        _validate();
        return state.exists( name );
    }

    private function _validate():Void {
        if (state == null)
            pull();
    }

    /**
      * bind a property
      */
    private function fwd(name:String, ?dv:Dynamic):Void {
        defineGetter(name, get.bind(name));
        defineSetter(name, set.bind(name, _));
        if (dv != null && nag(name) == null) {
            nas(name, dv);
        }
    }

    /**
      * use metadata to bind properties
      */
    private function __bindMeta() {
        var cm = Meta.getType(Type.getClass(this));
        var bmd:Null<Array<String>> = untyped cm.bind;
        if (bmd != null) {
            for (prop in bmd) {
                //trace('bind $prop to Storage');
                fwd( prop );
            }
        }
    }

/* === Computed Instance Fields === */

    public var port(get, set):Port<String>;
    private inline function get_port() return modem.port;
    private inline function set_port(v) return (modem.port = v);

/* === Instance Fields === */

    public var modem : Modem<String, Object>;

    private var state : Null<Object>;
}
