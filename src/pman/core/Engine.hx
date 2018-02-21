package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import pman.core.engine.*;
import pman.edb.*;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class Engine {
    /* Constructor Function */
    public function new():Void {
        executor = new Executor();
        dialogs = new Dialogs( this );
        appDir = new AppDir();
        db = new PManDatabase();

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

    public inline function isReady():Bool { return rs.isReady(); }
    public inline function onReady(f: Void->Void):Void return rs.on( f );

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

    private var rs: OnceSignal;
}
