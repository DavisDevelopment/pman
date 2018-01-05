package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.db.*;
import pman.bg.tasks.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;
using tannus.async.Asyncs;

class Media {
    /* Constructor Function */
    public function new(src: MediaSource):Void {
        id = null;
        source = src;
        uri = source.toUri();
        title = null;
    }

/* === Instance Methods === */

    /**
      * load [this]'s data
      */
    public function getData(?done: Cb<MediaData>):Promise<MediaData> {
        return wrap(Promise.create({
            if (hasData()) {
                return data;
            }
            else {
                var loader = new LoadMediaData(this, Database.instance);
                loader.run(function(?error, ?data) {
                    if (error != null) {
                        throw error;
                    }
                    else if (data != null) {
                        setData( data );
                        return this.data;
                    }
                });
            }
        }), done);
    }

    /**
      * export as a MediaRow
      */
    public function toRow():MediaRow {
        var row:MediaRow = {
            _id: id,
            title: title,
            uri: source.toUri()
        };
        if (hasData()) {
            row.data = data.toRow();
        }
        return row;
    }

    /**
      * apply [row] to [this]
      */
    public function applyRow(row:MediaRow, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        steps.push(function(next: VoidCb) {
            this.id = row._id;
            this.title = row.title;
            next();
        });
        steps.push(function(next: VoidCb) {
            if (row.data != null) {
                var dat = new MediaData();
                dat.pullRow(row.data, next);
            }
            else {
                next();
            }
        });
        steps.series( done );
    }

    /**
      * set [this]'s _data field
      */
    public function setData(d: MediaData):Void {
        if (hasData()) {
            data.ignore();
            data.link( false );
        }

        data = d;
        applyData( data );
        data.observe(function() {
            applyData( this.data );
        });
        data.link();
    }

    /**
      * copy [row]'s data onto [this]
      */
    private function applyData(row: MediaData):Void {
        views = row.views;
        starred = row.starred;
        rating = row.rating;
        contentRating = row.contentRating;
        channel = row.channel;
        description = row.description;
        marks = row.marks.copy();
        tags = row.tags.copy();
        actors = row.actors.copy();
        meta = row.meta;
        duration = meta.duration;
    }

    /**
      * check if [this] Media has its "_data" field
      */
    public inline function hasData():Bool {
        return (data != null);
    }

    /**
      * create and return a deep-copy of [this]
      */
    public function clone():Media {
        var copy:Media = new Media( source );
        copy.setData(data.clone());
        return copy;
    }

/* === Instance Fields === */

    public var id: Null<String>;
    public var source: MediaSource;
    public var uri: String;
    public var title: Null<String>;

    /* -- data fields -- */
    public var views: Null<Int>;
    public var starred: Null<Bool>;
    public var rating: Null<Float>;
    public var contentRating: Null<String>;
    public var channel: Null<String>;
    public var description: Null<String>;
    public var marks: Null<Array<String>>;
    public var tags: Null<Array<String>>;
    public var actors: Null<Array<Actor>>;
    public var duration: Null<Float>;
    public var mimeType: Null<String>;
    public var meta: Null<MediaMetadata>;

    public var cache_data: Bool = true;

    public var data: Null<MediaData>;

/* === Static Methods === */

    public static function fromRow(row: MediaRow, ?done:Cb<Media>):Promise<Media> {
        var res = Promise.create({
            var media:Media = new Media(row.uri.toMediaSource());
            media.applyRow(row, function(?error) {
                if (error != null) {
                    throw error;
                }
                else {
                    return media;
                }
            });
        });
        if (done != null) {
            res.toAsync( done );
        }
        return res;
    }

    private static function wrap<T, P:Promise<T>>(promise:P, ?callback:Cb<T>):P {
        if (callback != null) {
            promise.toAsync( callback );
        }
        return promise;
    }
}
