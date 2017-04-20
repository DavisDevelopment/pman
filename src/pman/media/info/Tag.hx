package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.*;
import pman.db.MediaStore;
import pman.db.TagsStore;
import pman.media.MediaType;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class Tag {
    /* Constructor Function */
    public inline function new(name:String, ?type:TagType):Void {
        this.name = name;
        this.type = (type != null ? type : Normal);
    }

/* === Instance Methods === */

    /**
      * create and return an exact copy of [this] Tag
      */
    public function clone():Tag {
        return new Tag(name, type);
    }

    /**
      * convert to a TagRow
      */
    public function toRow():TagRow {
        return {
            name: name,
            type: Serializer.run( type )
        };
    }

/* === Instance Fields === */

    public var name(default, null):String;
    public var type(default, null):TagType;

/* === Static Methods === */

    public static function fromRow(row : TagRow):Tag {
        return new Tag(row.name, Unserializer.run(row.type));
    }
}

enum TagType {
    Normal;
}
