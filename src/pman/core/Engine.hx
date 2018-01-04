package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;

import pman.core.engine.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class Engine {
    /* Constructor Function */
    public function new():Void {
        executor = new Executor();
        dialogs = new Dialogs( this );
    }

/* === Instance Methods === */

/* === Instance Fields === */

    // a micro-task manager and executor
    public var executor : Executor;

    // dialog manager instance
    public var dialogs : Dialogs;
}
