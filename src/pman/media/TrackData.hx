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
import pman.media.MediaInfo;

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
      * copy data from [row] onto [this]
      */
    public function pullRow(row : MediaInfoRow):Void {
        media_id = row.id;
        views = row.views;
        starred = row.starred;
        if (row.meta != null) {
            meta = row.meta;
        }
    }

/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<Int>;
    public var views : Int;
    public var starred : Bool;

    public var meta : Null<MediaMetadata>;
}
