package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry.FSEntryType;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.MediaType;

import electron.ext.FileFilter;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class FileFilterProbe extends DirectoryProbe {
    /* Constructor Function */
    public function new():Void {
        super();

        filter = null;
    }

/* === Instance Methods === */

    public inline function setFilter(filter : FileFilter):Void {
        this.filter = filter;
    }

    override function test_file(file : File):Bool {
        if (filter != null) {
            return filter.test(file.path.toString());
        }
        else {
            throw 'Error: FileFilterProbe was run without being given a filter';
        }
    }

/* === Instance Fields === */

    public var filter : Null<FileFilter>;
}
