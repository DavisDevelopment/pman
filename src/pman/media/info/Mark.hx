package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.media.Duration;

import gryffin.display.Image;

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
      * get a BundleItem for [this] Mark
      */
    public function getThumbnailBundleItem(track:Track, ?size:String):Promise<BundleItem> {
        var bundle = track.getBundle();
        return bundle.getSnapshot(time, size);
    }

    /**
      * get the URI for the thumbnail for [this] Mark
      */
    public function getThumbnailURI(track:Track, ?size:String):Promise<String> {
        return getThumbnailBundleItem(track, size).transform.fn(_.getURI());
    }

    /**
      * load the thumbnail for [this] Mark
      */
    public function getThumbnailImage(track:Track, ?size:String):Promise<Image> {
        return Promise.create({
            var p = getThumbnailBundleItem(track, size);
            p.then(function( item ) {
                item.toImage(function(?error, ?image) {
                    if (error != null)
                        throw error;
                    else if (image != null)
                        return image;
                });
            });
            p.unless(function(error) {
                throw error;
            });
        });
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

    /**
      * serialize [this] Mark
      */
    @:keep
    public function hxSerialize(s : Serializer):Void {
        inline function w(x:Dynamic) s.serialize( x );

        w( type );
        w( time );
    }

    /**
      * deserialize [this] Mark
      */
    @:keep
    public function hxUnserialize(u : Unserializer):Void {
        inline function v<T>():T return u.unserialize();

        type = v();
        time = v();
    }

    /**
    /**
      * get the 'first' word in a piece of text
      */
    private function firstWord(text : String):Null<String> {
        text = text.trim();
        if (text.empty())
            return null;
        else {
            return text.before(' ');
        }
    }

    /**
    /**
      * get the 'first word' of [this] bookmark's name
      */
    public function fw():Maybe<String> {
        switch ( type ) {
            case Named( text ):
                return firstWord( text );

            default:
                return null;
        }
    }

    /**
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
