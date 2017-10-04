package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.media.*;
import pman.media.MediaType;
import pman.edb.*;
import pman.edb.ActorStore;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class Actor implements IComparable<Actor> {
    public function new(name:String, ?id:String):Void {
        this.name = name;
        this.id = id;
        //this.gender = gender;
    }

/* === Instance Methods === */

    /**
      * create and return a copy of [this] Actor object
      */
    public function clone():Actor {
        return new Actor(name, id);
    }

    /**
      * convert [this] Actor object to an ActorRow object
      */
    public function toRow():ActorRow {
        return {
            _id: id,
            name: name
        };
    }

    /**
      * compare [this] Actor to [other]
      */
    public function compareTo(other : Actor):Int {
        return Reflect.compare(name, other.name);
    }

    /**
      * check for equality between [this] and [other]
      */
    public function equals(other : Actor):Bool {
        return (this == other || (
            (name == other.name)
        ));
    }

/* === Instance Fields === */

    public var id : Null<String>;
    public var name : String;

/* === Static Methods === */

    /**
      * convert an ActorRow to an Actor object
      */
    public static function fromRow(row : ActorRow):Actor {
        return new Actor(
            row.name,
            row._id
        );
    }
}

enum ActorGender {
    Male;
    Female;
}
