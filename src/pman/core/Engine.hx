package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class Engine {
    /* Constructor Function */
    public function new():Void {
        executor = new Executor();
    }

/* === Instance Methods === */

/* === Instance Fields === */

    // a micro-task manager and executor
    public var executor : Executor;
}
