package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;
import pman.Globals.*;

import nedb.DataStore;

import Slambda.fn;
import tannus.math.TMath.*;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.VoidAsyncs;

class PManDatabase {
    /* Constructor Function */
    public function new():Void {
        path = (Paths.userData().plusString('pmdb'));
        ops = new Operators();

        rs = new ReadySignal();
    }

/* === Instance Methods === */

    public function init(?done : VoidCb):Void {
        if (!Fs.exists( path )) {
            Fs.createDirectory( path );
        }

        defer(function() {
            var tasks:Array<VoidAsync> = new Array();
            inline function step(a : VoidAsync) tasks.push( a );

            // create TableWrapper properties
            step(function(next) {
                try {
                    mediaStore = wrap('media', MediaStore);
                    actorStore = wrap('actors', ActorStore);

                    var tables = [
                        mediaStore,
                        actorStore
                    ];
                    VoidAsyncs.series(untyped tables.map.fn(_.init.bind(_)), next);
                }
                catch (error : Dynamic) {
                    next( error );
                }
            });

            // create other properties
            step(function(next) {
                defer(function() {

                    configInfo = new ConfigInfo();
                    preferences = new Preferences();

                    next();
                });
            });

            tasks.series(function(?error) {
                if (done != null) {
                    done( error );
                }
            });
        });
    }

    /**
      * create a TableWrapper
      */
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
        return Type.createInstance(type, untyped [this, store]);
    }

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
    public function onready(action : Void->Void):Void rs.await( action );

    /**
      * get the full path to the DataStore file
      */
    public function dsfilename(name : String):String {
        return Std.string(path.plusString( name ).normalize());
    }

/* === Instance Fields === */

    public var path: Path;
    public var ops : Operators;
    public var mediaStore : MediaStore;
    public var actorStore : ActorStore;

    public var configInfo : ConfigInfo;
    public var preferences : Preferences;
    
    private var rs : ReadySignal;
}
