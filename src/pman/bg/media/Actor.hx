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

import pman.bg.media.ActorRow;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class Actor {
    /* Constructor Function */
    public function new(?row: ActorRow):Void {
        if (row == null) {
            row = {
                name: 'John Doe'
            };
        }
        applyRow( row );
    }

/* === Instance Methods === */

    /**
      * copy data from [row] onto [this]
      */
    public inline function applyRow(row: ActorRow):Void {
        id = row._id;
        name = row.name;
        aliases = (row.aliases != null ? row.aliases : new Array());
        dob = row.dob;
    }

    /**
      * export [this] onto an ActorRow instance
      */
    public function toRow():ActorRow {
        return {
            _id: id,
            name: name,
            aliases: (aliases.empty() ? null : aliases.copy()),
            dob: dob
        };
    }

/* === Instance Fields === */

    public var id: Null<String>;
    public var name: String;
    public var aliases: Array<String>;
    public var dob: Null<Date>;
}
