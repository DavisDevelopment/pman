package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;
import pman.core.ApplicationState;
import pman.Globals.*;

import edis.libs.nedb.DataStore;

import pman.bg.db.*;
import pman.bg.Dirs;

import Slambda.fn;
import tannus.math.TMath.*;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.VoidAsyncs;

class PManDatabase extends Database {
    /* Constructor Function */
    public function new():Void {
        super();

        //path = (Paths.userData().plusString('pmdb'));
        path = Dirs.dbPath();
        ops = new Operators();

        if (instance == null) {
            instance = this;
        }
    }

/* === Instance Methods === */

    override function init(?done : VoidCb):Void {
        if (!Fs.exists( path )) {
            Fs.createDirectory( path );
        }

        if (done == null)
            done = VoidCb.noop;
        done = done.wrap(function(_done, ?error) {
            //TODO
            _done( error );
        });

        super.init( done );
    }

    /**
      * do the stuff
      */
    override function _build():Void {
        super._build();

        require(function(next) {
            defer(function() {
                mediaStore = media;
                actorStore = actors;

                next();
            });
        });

        require(function(next) {
            defer(function() {
                configInfo = new ConfigInfo();
                preferences = new Preferences();

                next();
            });
        });

        require(function(next) {
            defer(function() {
                appState = new ApplicationState();

                next();
            });
        });
    }

    /**
      * create a TableWrapper
      */
    /*
    private function wrap<T:TableWrapper>(name:String, ?type:Class<T>):T {
        if (type == null) {
            type = untyped TableWrapper;
        }
        if (!name.endsWith('.db')) {
            name += '.db';
        }
        var store:DataStore = new DataStore({
            filename: dsfilename( name ),
            afterSerialization: afterSerialization,
            beforeDeserialization: beforeDeserialization
        });
        return Type.createInstance(type, untyped [store]);
    }
    */

    /**
      * alter the serialization of documents
      */
    private function afterSerialization(data : String):String {
        return data;
    }

    /**
      * alter the deserialization of a document
      */
    private function beforeDeserialization(data : String):String {
        return data;
    }

    /**
      * queue [action] for when [this] database has been declared 'ready'
      */
    //public function onready(action : Void->Void):Void rs.await( action );

    /**
      * get the full path to the DataStore file
      */
    //public function dsfilename(name : String):String {
        //return Std.string(path.plusString( name ).normalize());
    //}

    public static function get(?safeAction: PManDatabase->Void):PManDatabase {
        var res = instance;
        if (res == null) {
            res = new PManDatabase();
        }
        if (safeAction != null) {
            res.onready(safeAction.bind(res));
        }
        return res;
    }

    public static var instance:Null<PManDatabase> = null;

/* === Instance Fields === */

    public var path: Path;
    public var ops : Operators;
    public var mediaStore : MediaStore;
    public var actorStore : ActorStore;

    public var configInfo : ConfigInfo;
    public var preferences : Preferences;
    public var appState : ApplicationState;
    
    //private var rs : ReadySignal;
}
