package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import Slambda.fn;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class Tag implements tannus.ds.IComparable<Tag> {
    /* Constructor Function */
    public inline function new(row: TagRow) {
        this.name = row.name;
        this.id = row._id;
    }

/* === Instance Methods === */

    /**
      * convert [this] to a TagRow
      */
    public function toRow():TagRow {
        var row:TagRow = {
            name: name.trim()
        };
        if (id != null) {
            row._id = id;
        }
        return row;
    }

    /**
      * create and return a deep-copy of [this]
      */
    public inline function clone():Tag {
        return new Tag(toRow());
    }

    /**
      * check for equality
      */
    public function equals(other: Tag):Bool {
        return (name == other.name);
    }

    /**
      * compare [this] to [other]
      */
    public function compareTo(other: Tag):Int {
        return Reflect.compare(name, other.name);
    }

/* === Instance FIelds === */

    public var id: Null<String>;
    public var name: String;
}
