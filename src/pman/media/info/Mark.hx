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

@:expose('Mark')
class Mark {
    /* Constructor Function */
    public function new(type:MarkType, time:Float):Void {
        this.type = type;
        this.time = time;
    }

/* === Instance Methods === */

    /**
      * clone [this] Mark
      */
    public inline function clone():Mark {
        return new Mark(type, time);
    }

    /**
      * convert [this] Mark to a ByteArray
      */
    public function toByteArray():ByteArray {
        var b = new ByteArrayBuffer();
        b.addString(type.getName());
        switch ( type ) {
            case Named( name ):
                b.addString( name );
            default:
                null;
        }
        b.addFloat( time );
        return b.getByteArray();
    }

    /**
      * build a new Mark from a ByteArray
      */
    public static function fromByteArray(b : ByteArray):Mark {
        b.seek( 0 );
        var type:MarkType;
        var time:Float;
        var ename = b.readString(b.readInt32());
        if (ename == 'Named') {
            var name = b.readString(b.readInt32());
            type = Named( name );
        }
        else {
            type = MarkType.createByName( ename );
        }
        time = b.readFloat();
        return new Mark(type, time);
    }

    public static function create(name:String, time:Float):Mark {
        return new Mark(Named(name), time);
    }

/* === Instance Fields === */

    public var type : MarkType;
    public var time : Float;
}

enum MarkType {
    Begin;
    End;
    LastTime;

    Named(name : String);
}
