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

        _changed = new VoidSignal();
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

    /**
      * declare whether [this] object will announce changes made to it
      */
    public inline function link(status:Bool=true):Void {
        _linked = status;
    }

/* === Setter Methods === */

    private function set_views(v) {
        var res = (views = v);
        return res;
    }

    private function set_starred(v) {
        var res = (starred = v);
        return res;
    }

    private function set_rating(v) {
        var res = (rating = v);
        return res;
    }

    private function set_channel(v) {
        var res = (channel = v);
        return res;
    }

    private function set_contentRating(v) {
        var res = (contentRating = v);
        return res;
    }

    private function set_description(v) {
        var res = (description = v);
        return res;
    }

    private function set_marks(v) {
        var res = (marks = v);
        return res;
    }

    private function set_tags(v) {
        var res = (tags = v);
        return res;
    }

    private function set_actors(v) {
        var res = (actors = v);
        return res;
    }

    private function set_meta(v) {
        var res = (meta = v);
        return res;
    }

/* === Instance Fields === */

    public var views(default, set): Int;
    public var starred(default, set): Bool;
    public var rating(default, set): Null<Float>;
    public var contentRating(default, set): Null<String>;
    public var channel(default, set): Null<String>;
    public var description(default, set): Null<String>;
    public var marks(default, set): Array<String>;
    public var tags(default, set): Array<String>;
    public var actors(default, set): Array<Actor>;

    public var meta(default, set): Null<MediaMetadata>;

    public var _changed: VoidSignal;
    public var _linked: Bool = false;
    private var _suspended: Bool = false;
    private var _susHasChanged: Bool = false;
}
