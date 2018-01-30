package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;

import pman.core.engine.*;
import pman.edb.*;

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
    }

/* === Instance Methods === */

/* === Instance Fields === */

    // a micro-task manager and executor
    public var executor : Executor;

    // dialog manager instance
    public var dialogs : Dialogs;

    // application's database
    public var db : PManDatabase;

    // utility object for working with files and paths related to the application's location on the host filesystem
    public var appDir : AppDir;
}
