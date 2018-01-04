package pman.bg.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import edis.libs.nedb.*;
import edis.storage.db.*;

import pman.bg.Dirs;

import Slambda.fn;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;

class Table extends TableWrapper {
    /* Constructor Function */
    public function new(store: DataStore):Void {
        super( store );
    }

/* === Instance Methods === */

/* === Instance Fields === */
}
