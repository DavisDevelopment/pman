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
import pman.media.MediaSource;

import pman.tools.mediatags.MediaTagReader;
import pman.tools.mp4box.MP4Box;
import pman.tools.mp3duration.MP3Duration;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class MediaInfo {
    /* Constructor Function */
    public function new():Void {
        id = null;
        uri = '';
        views = 0;
        starred = false;
        duration = null;
        media_type = MediaType.MTVideo;
    }

/* === Instance Methods === */

    /**
      * create and return a clone of [this] object
      */
    public function clone():MediaInfo {
        var c = new MediaInfo();
        c.id = id;
        c.views = views;
        c.starred = starred;
        c.duration = duration;
        c.media_type = media_type;
        return c;
    }

    /**
      * load all fields
      */
    public function load(tabl:MediaStore, done:Void->Void):Void {
        if (hasAllFields()) {
            defer( done );
        }
        else {
            var stack = new AsyncStack();
            stack.push(function(next) {
                if (!hasAllDbFields()) {
                    loadMissingInfo_db(tabl, next);
                }
            });
            stack.push(function(next) {
                if (!hasAllFsFields()) {
                    loadMissingInfo_fs( next );
                }
            });
            stack.run( done );
        }
    }

    /**
      * load in missing information (filesystem)
      */
    public function loadMissingInfo_fs(complete : Void->Void):Void {
        var mt:Null<Mime> = getMimeType();
        if (mt == null) {
            complete();
            return ;
        }
        else {
            var path:Null<Path> = getPath();

            // MP3 Data
            if (mt == 'audio/mpeg') {
                if (path != null) {
                    var dp = MP3Duration.getDuration( path );
                    dp.then(function(dur : Float) {
                        this.duration = dur;
                        complete();
                    });
                    dp.unless(function(error) {
                        throw error;
                        complete();
                    });
                }
                else {
                    complete();
                }
            }
            else {
                trace('No info loaders for "$mt" available');
            }
        }
    }

    /**
      * load in missing information (database)
      */
    public function loadMissingInfo_db(table:MediaStore, complete:Void->Void):Void {
        defer( complete );
    }

    /**
      * pull data from MediaInfoRow onto [this]
      */
    public function pullRow(row : MediaInfoRow):Void {
        id = row.id;
        views = row.views;
        starred = row.starred;
        duration = row.duration;
    }

    /**
      * check that all fields are assigned
      */
    public inline function hasAllFields():Bool {
        return (hasAllFsFields() && hasAllDbFields());
    }

    /**
      * checks that all database-specific fields are assigned
      */
    public inline function hasAllDbFields():Bool {
        return (
            (id != null) &&
            (views != null) &&
            (starred != null)
        );
    }

    public inline function hasAllFsFields():Bool {
        return (
            (duration != null)
        );
    }

    /**
      * get the MIME type
      */
    public function getMimeType():Null<Mime> {
        if (uri == '') {
            return null;
        }
        else {
            if (uri.startsWith('file:')) {
                var path:Path = new Path(uri.after('file:').stripSlashSlash());
                switch ( path.extension ) {
                    case 'mp4': 
                        return 'video/mp4';
                    case 'mp3': 
                        return 'audio/mpeg';
                    case 'webm': 
                        return 'video/webm';
                    case 'wav': 
                        return 'audio/wav';
                    default: 
                        throw 'Error: Unknown file type';
                        return null;
                }
            }
            else {
                return null;
            }
        }
    }

    /**
      * get the filesystem Path
      */
    public function getPath():Null<Path> {
        if (uri == '') {
            return null;
        }
        else {
            if (uri.startsWith('file:')) {
                var path:Path = new Path(uri.after('file:').stripSlashSlash());
                return path;
            }
            else return null;
        }
    }

/* === Instance Fields === */

    // generic fields
    public var media_type : MediaType;
    public var uri : String;

    // database fields
    public var id : Null<Int>;
    public var views : Null<Int>;
    public var starred : Null<Bool>;

    // filesystem fields

    // hybrid fields
    public var duration : Null<Float>;
}
