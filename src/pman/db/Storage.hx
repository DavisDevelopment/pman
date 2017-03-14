package pman.db;

import tannus.ds.*;
import tannus.io.*;
import tannus.mvc.Requirements;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Storage {
    /* Constructor Function */
    public function new():Void {
        _ready = false;
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    public function init(done : Void->Void):Void {
        fetch(function() {
            _ready = true;
            done();
        });
    }

    public function get<T>(key : String):Null<T> {
        return null;
    }
    public function set<T>(key:String, value:T):T {
        return value;
    }
    public function exists(key : String):Bool {
        return false;
    }
    public function remove(key : String):Bool {
        return false;
    }
    public function keys():Array<String> {
        return [];
    }

    /**
      * pull remote data
      */
    public function fetch(done : Void->Void):Void {
        defer( done );
    }

    /**
      * push local state to the remote
      */
    public function push(done : Void->Void):Void {
        fetch(function() {
            defer( done );
        });
    }

    /**
      * sync with the remote
      */
    public function sync(done : Void->Void):Void {
        push( done );      
    }

/* === Instance Fields === */

    private var _ready : Bool;
}
