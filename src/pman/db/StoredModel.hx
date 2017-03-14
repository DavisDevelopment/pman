package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;

import pman.core.*;
import pman.media.*;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class StoredModel extends Model {
    /* Constructor Function */
    public function new():Void {
        super();

        storage = new Storage();
    }

/* === Instance Methods === */

    override function init(?done : Void->Void):Void {
        require('storage', function(scb) {
            storage.init( scb );
        });

        super.init( done );
    }

    override function getAttribute<T>(name : String):Null<T> {
        return storage.get( name );
    }
    override function setAttribute<T>(name:String, value:T):T {
        return storage.set(name, value);
    }
    override function hasAttribute(name : String):Bool {
        return storage.exists( name );
    }
    override function removeAttribute(name : String):Bool {
        return storage.remove( name );
    }
    override function allAttributes():Array<String> return storage.keys();

    /*
    override function sync(done : Void->Void):Void {

    }
    */

/* === Instance Fields === */

    private var storage(default, null):Storage;
}
