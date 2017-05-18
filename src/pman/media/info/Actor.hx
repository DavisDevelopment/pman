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
import pman.db.ActorsStore;
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

class Actor {
    public function new(name:String, ?id:Int, ?gender:ActorGender):Void {
        this.name = name;
        this.id = id;
        this.gender = gender;
    }

/* === Instance Methods === */

    public function clone():Actor {
        return new Actor(name, id, gender);
    }

    public function toRow():ActorRow {
        return {
            id: id,
            name: name,
            gender: (gender!=null?gender.getIndex():null)
        };
    }

/* === Instance Fields === */

    public var id : Null<Int>;
    public var name : String;
    public var gender : Null<ActorGender>;

/* === Static Methods === */

    public static function fromRow(row : ActorRow):Actor {
        return new Actor(row.name, row.id, (row.gender != null?ActorGender.createByIndex( row.gender ):null));
    }
}

enum ActorGender {
    Male;
    Female;
}
