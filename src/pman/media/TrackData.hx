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

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

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

/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<Int>;
    public var views : Int;
    public var starred : Bool;

    public var meta : Null<MediaMetadata>;
}
