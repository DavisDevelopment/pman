package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import edis.storage.fs.async.FileSystem as AsyncFs;

import pman.core.engine.*;
import pman.edb.*;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

/**
  app's main engine
 **/
class Engine {
    /* Constructor Function */
    public function new():Void {
        executor = new Executor();
        dialogs = new Dialogs( this );
        appDir = new AppDir();
        db = new PManDatabase();

        /* this line (in theory) is that need be changed in order to have the app use a different means of data storage */
        fileSystem = AsyncFs.node();

        rs = new OnceSignal();
    }

/* === Instance Methods === */

    /**
      * initialize [this] Engine
      */
    public function init(?done: VoidCb):Void {
        if (done == null) {
            done = function(?error: Dynamic) {
                if (error != null) {
                    report( error );
                }
            };
        }

        db.init(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                rs.announce();
                done();
            }
        });
    }

    /**
      check whether [this] Engine is 'ready'
     **/
    public inline function isReady():Bool { 
        return rs.isReady(); 
    }

    /**
      delay [f]'s invokation until [this] Engine is ready
     **/
    public inline function onReady(f: Void->Void):Void {
        return rs.on( f );
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    // a micro-task manager and executor
    public var executor : Executor;

    // dialog manager instance
    public var dialogs : Dialogs;

    // application's database
    public var db : PManDatabase;

    // utility object for working with files and paths related to the application's location on the host filesystem
    public var appDir : AppDir;

    /**
      singleton FileSystem instance to be used by the application at large
      ---
        this should make future support of additional non-electron platforms 
        MUCH easier, as most app functions are already generally platform-independent, 
        and the exceptions to that are almost exclusively FileSystem-driven persistence of
        application data
     **/
    public var fileSystem : AsyncFs;

    // signal for marking when [this] Engine is ready
    private var rs: OnceSignal;
}
