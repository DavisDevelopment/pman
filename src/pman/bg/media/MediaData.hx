package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;
import pman.bg.db.*;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.URITools;

class MediaData {
    /* Constructor Function */
    public function new():Void {
        views = 0;
        starred = false;
        rating = null;
        contentRating = 'NR';
        channel = null;
        description = null;
        tags = new Array();
        marks = new Array();
        actors = new Array();
        meta = null;

    }

/* === Instance Methods === */

    /**
      * pull [row]'s data onto [this]
      */
    public function pullRow(row:MediaDataRow, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();

        // handle base fields
        steps.push(function(next: VoidCb) {
            views = row.views;
            starred = row.starred;
            rating = row.rating;
            contentRating = row.contentRating;
            channel = row.channel;
            description = row.description;
            tags = row.tags.copy();
            meta = null;
            if (row.meta != null) {
                meta = new MediaMetadata( row.meta );
            }
            next();
        });

        // handle marks
        steps.push(function(next) {
            marks = new Array();
            for (m in row.marks) {
                //TODO
            }
            next();
        });

        // handle actors
        steps.push(function(next) {
            actors = new Array();
            for (a in row.actors) {
                //TODO
            }
            next();
        });

        steps.series( done );
    }

    /**
      * get [this] as a MediaDataRow object
      */
    public function toRow():MediaDataRow {
        return {
            views: views,
            starred: starred,
            rating: rating,
            contentRating: contentRating,
            channel: channel,
            description: description,
            marks: [],
            tags: tags.copy(),
            actors: [],
            meta: (meta != null ? meta.toRaw() : null)
        };
    }

    /**
      * create and return a deep-copy of [this]
      */
    public function clone():MediaData {
        var copy:MediaData = new MediaData();
        copy.views = views;
        copy.starred = starred;
        copy.contentRating = contentRating;
        copy.channel = channel;
        copy.description = description;
        copy.marks = marks.copy();
        copy.tags = tags.copy();
        copy.actors = actors.map(x->x.clone());
        copy.meta = (meta != null ? meta.clone() : null);
        return copy;
    }

/* === Instance Fields === */

    public var views: Int;
    public var starred: Bool;
    public var rating: Null<Float>;
    public var contentRating: Null<String>;
    public var channel: Null<String>;
    public var description: Null<String>;
    public var marks: Array<String>;
    public var tags: Array<String>;
    public var actors: Array<Actor>;

    public var meta: Null<MediaMetadata>;
}
