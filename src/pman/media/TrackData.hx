package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.media.MediaType;
import pman.async.Mp4InfoLoader;
import pman.media.info.*;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;
import tannus.node.Buffer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class TrackData {
    /* Constructor Function */
    public function new(track : Track):Void {
        this.track = track;

        media_id = null;
        views = 0;
        starred = false;
        marks = new Array();
    }

/* === Instance Methods === */

    /**
      * pull data from a MediaInfoRow
      */
    public function pullRaw(row : MediaInfoRow):Void {
        media_id = row.id;
        views = row.views;
        starred = row.starred;
        if (row.meta != null) {
            meta = new MediaMetadata();
            meta.pullRaw( row.meta );
        }
        marks = row.marks.map( Unserializer.run );
    }

    /**
      * convert [this] to a MediaInfoRow
      */
    public function toRaw():MediaInfoRow {
        if (media_id == null) {
            throw 'What the fuck?';
        }

        return {
            id: media_id,
            views: views,
            starred: starred,
            marks: marks.map( Serializer.run ),
            meta: (meta != null ? meta.toRaw() : null)
        };
    }

    /**
      * push [this] TrackData to the database
      */
    public function save(?done:Void->Void, ?store:MediaStore):Void {
        if (store == null) {
            store = BPlayerMain.instance.db.mediaStore;
        }
        var prom = store.putMediaInfoRow(toRaw());
        prom.then(function( row ) {
            pullRaw( row );

            if (done != null) {
                done();
            }
        });
        prom.unless(function( error ) {
            throw error;
        });
    }

    /**
      * add a new Mark to [this]
      */
    public function addMark(mark : Mark):Void {
        switch ( mark.type ) {
            case Begin, End, LastTime:
                marks = marks.filter.fn(!_.type.equals( mark.type ));
                marks.push( mark );

            case Named( name ):
                marks.push( mark );
        }
    }

    /**
      * remove all marks of the given type
      */
    public inline function removeMarksOfType(mt : MarkType):Void {
        filterMarks.fn(!_.type.equals( mt ));
    }
    public inline function removeBeginMark():Void removeMarksOfType( Begin );
    public inline function removeEndMark():Void removeMarksOfType( End );
    public inline function removeLastTimeMark():Void removeMarksOfType( LastTime );

    /**
      * filter [marks]
      */
    public inline function filterMarks(f : Mark->Bool):Void {
        marks = marks.filter( f );
    }

    public inline function getMarkq(f : Mark->Bool):Null<Mark> {
        return marks.firstMatch( f );
    }
    public inline function getMarkByType(type : MarkType):Null<Mark> {
        return getMarkq.fn(_.type.equals( type ));
    }
/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<Int>;
    public var views : Int;
    public var starred : Bool;
    public var marks : Array<Mark>;

    public var meta : Null<MediaMetadata>;
}
