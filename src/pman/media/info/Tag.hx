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
import pman.async.*;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.ds.SortingTools.*;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.ds.SortingTools;
using pman.async.VoidAsyncs;
using pman.async.Asyncs;

@:expose('TrackTag')
class Tag implements IComparable<Tag> {
    /* Constructor Function */
    public inline function new(name:String, ?id:Int, ?type:TagType):Void {
        this.id = id;
        this.name = name;
        this.type = (type != null ? type : Normal);
        this.aliases = (aliases != null ? aliases : []);
        this.supers = null;
    }

/* === Instance Methods === */

    /**
      * create and return an exact copy of [this] Tag
      */
    public function clone():Tag {
        return new Tag(name, id, type);
    }

    /**
      * convert to a TagRow
      */
    public function toRow():TagRow {
        var row:TagRow = {
            name: name,
            type: Serializer.run( type ),
            aliases: aliases
        };
        if (id != null)
            row.id = id;
        if (supers != null) {
            row.supers = [];
            for (s in supers) {

            }
        }
        return row;
    }

    /**
      * resolve derived tag's 'supers' into two-dimensional Array of dependencies that can be resolved top-down
      */
    public function resolveDependencies():Array<Array<Tag>> {
        var deps:Array<Array<Tag>> = new Array();
        // create, if necessary, and return a 'layer' of the dependency hierarchy
        inline function layer(i : Int):Array<Tag> {
            return deps[i] == null ? deps[i] = [] : deps[i];
        }
        // write an Array of tags onto the specified layer
        inline function mergelayer(i:Int, dl:Array<Tag>)
            deps[i] = layer( i ).concat( dl );

        if (supers == null) {
            return deps;
        }
        else {
            for (st in supers) {
                var dh = st.resolveDependencies();
                for (i in 0...dh.length) {
                    var l = dh[i];
                    if (l != null) {
                        mergelayer(i, l);
                    }
                }
                layer(st.depCount()).push( st );
            }
            return deps;
        }
    }

    /**
      * check how many 'dependencies' this tag has
      */
    public inline function depCount():Int {
        return (supers == null ? 0 : supers.length);
    }

    /**
      * compare [this] Tag to another Tag
      */
    public function compareTo(other : Tag):Int {
        return Reflect.compare(name, other.name);
    }

/* === Instance Fields === */

    public var name: String;
    public var id: Null<Int>;
    public var aliases: Array<String>;
    public var supers: Null<Array<Tag>> = null;
    public var type: TagType;

/* === Static Methods === */

    public static function fromRow(row : TagRow):Tag {
        return new Tag(row.name, row.id, Unserializer.run(row.type));
    }
}

enum TagType {
    Normal;
}
