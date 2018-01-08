package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;
import pman.bg.media.Mark;
import pman.bg.db.*;
import pman.bg.tasks.*;

import haxe.Serializer;
import haxe.Unserializer;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.DictTools;


class MediaData {
    /* Constructor Function */
    public function new(?id:String, ?uri:String):Void {
        mediaId = id;
        mediaUri = uri;
        views = 0;
        starred = false;
        rating = null;
        contentRating = 'NR';
        channel = null;
        description = null;
        attrs = new Dict();
        tags = new Array();
        marks = new Array();
        actors = new Array();
        meta = null;

        _changed = new VoidSignal();
    }

/* === Instance Methods === */

    /**
      * check if [this] is in its "default" ("empty") state
      */
    public function empty():Bool {
        return (
            (mediaId == null) &&
            (views == null || views == 0) &&
            (!starred) &&
            (rating == null) &&
            (contentRating == null || contentRating == 'NR') &&
            (channel == null) &&
            (description == null) &&
            (attrs == null) &&
            (tags.empty()) &&
            (marks.empty()) &&
            (actors.empty()) &&
            (meta == null)
        );
    }

    /**
      *
      */
    public function pullMediaRow(row:MediaRow, done:VoidCb):Void {
        this.mediaId = row._id;
        this.mediaUri = row.uri;
        
        if (row.data != null) {
            pullRow(row.data, done);
        }
        else {
            done();
        }
    }

    /**
      * pull [row]'s data onto [this]
      */
    public function pullRow(row:MediaDataRow, done:VoidCb):Void {
        var db:Database = Database.get();
        var steps:Array<VoidAsync> = new Array();

        //this.mediaId = row.actors

        // handle base fields
        steps.push(function(next: VoidCb) {
            suspendLinkage(function(me) {
                views = row.views;
                starred = row.starred;
                rating = row.rating;
                contentRating = row.contentRating;
                channel = row.channel;
                description = row.description;
                attrs = new Dict();
                if (row.attrs != null) {
                    attrs = row.attrs.toDict();
                }
                //tags = row.tags.copy();
                meta = null;
                if (row.meta != null) {
                    meta = new MediaMetadata( row.meta );
                }
            });
            next();
        });

        // handle tags
        steps.push(function(next) {
            var tagSteps:Array<VoidAsync> = new Array();
            if (row.tags == null)
                return next();
            // get array of tags in their raw form
            var rawTags = row.tags.copy();
            // temp variable that will become the value of [tags]
            var _tags = new Array();
            // for every 'raw tag'
            for (rt in rawTags) {
                // queue the 'loading' of [rt]
                tagSteps.push(function(nxt) {
                    _tags.push( rt );
                    nxt();
                });
            }
            // execute [tagSteps]
            tagSteps.series(function(?error) {
                if (error != null) {
                    return next( error );
                }
                else {
                    // assign value of [tags]
                    this.tags = _tags;
                    next();
                }
            });
        });

        // handle marks
        steps.push(function(next) {
            var _marks:Array<Mark> = new Array();
            var rawMarks = cast(row.marks.copy(), Array<Dynamic>);
            var resolver = new PatchTypeResolver();

            for (m in rawMarks) {
                if ((m is String)) {
                    var decoder = new Unserializer( m );
                    decoder.setResolver( resolver );

                    _marks.push(decoder.unserialize());
                }
                else if (Reflect.isObject( m )) {
                    _marks.push(Mark.fromJsonMark( m ));
                }
            }

            marks = _marks;

            next();
        });

        // handle actors
        steps.push(function(next) {
            var _actors = new Array();
            var rawActors = row.actors.copy();
            var actorSteps = new Array();

            for (name in rawActors) {
                actorSteps.push(function(nxt: VoidCb) {
                    var ap = db.actors.cogActor( name );
                    ap.then(function(actor: Actor) {
                        _actors.push( actor );
                        nxt();
                    }, nxt.raise());
                });
            }

            actorSteps.series(function(?error) {
                if (error != null) {
                    return next( error );
                }
                else {
                    this.actors = _actors;
                    next();
                }
            });
        });

        db.ensure(function() {
            steps.series( done );
        });
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
            attrs: attrs.toAnon(),
            marks: marks.map.fn(_.toJson()),
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
      * announce that [this] object has changed
      */
    private inline function announceChange():Void {
        if ( _linked ) {
            if ( _suspended ) {
                _susHasChanged = true;
            }
            else {
                _changed.fire();
            }
        }
    }

    /**
      * declare whether [this] object will announce changes made to it
      */
    public inline function link(status:Bool=true):Void {
        _linked = status;
    }

    /**
      * declare whether [this] object's linkage is suspended
      */
    public inline function sus(status:Bool=true):Void {
        _suspended = status;
        _susHasChanged = false;
    }

    /**
      * suspend the firing of [_changed] for every change made, and fire it only once,
      * if a change is made during the execution of [body] on [this]
      */
    public inline function suspendLinkage(body: MediaData->Void):Void {
        if (_linked && !_suspended) {
            sus( true );
            body( this );
            var hc:Bool = _susHasChanged;
            sus( false );
            if ( hc ) {
                announceChange();
            }
        }
    }

    /**
      * listen for change events
      */
    public inline function observe(onChange:Void->Void, once:Bool=false):Void {
        (once ? _changed.once : _changed.on)( onChange );
    }

    /**
      * stop listening for change events
      */
    public inline function ignore():Void {
        _changed.clear();
    }

/* === Setter Methods === */

    private function set_views(v) {
        var res = (views = v);
        announceChange();
        return res;
    }

    private function set_starred(v) {
        var res = (starred = v);
        announceChange();
        return res;
    }

    private function set_rating(v) {
        var res = (rating = v);
        announceChange();
        return res;
    }

    private function set_channel(v) {
        var res = (channel = v);
        announceChange();
        return res;
    }

    private function set_contentRating(v) {
        var res = (contentRating = v);
        announceChange();
        return res;
    }

    private function set_description(v) {
        var res = (description = v);
        announceChange();
        return res;
    }

    private function set_marks(v) {
        var res = (marks = v);
        announceChange();
        return res;
    }

    private function set_tags(v) {
        var res = (tags = v);
        announceChange();
        return res;
    }

    private function set_actors(v) {
        var res = (actors = v);
        announceChange();
        return res;
    }

    private function set_meta(v) {
        var res = (meta = v);
        announceChange();
        return res;
    }

/* === Instance Fields === */

    public var mediaId: Null<String>;
    public var mediaUri: Null<String>;

    public var views(default, set): Int;
    public var starred(default, set): Bool;
    public var rating(default, set): Null<Float>;
    public var contentRating(default, set): Null<String>;
    public var channel(default, set): Null<String>;
    public var description(default, set): Null<String>;
    public var attrs(default, set): Dict<String, Dynamic>;
    public var marks(default, set): Array<Mark>;
    public var tags(default, set): Array<String>;
    public var actors(default, set): Array<Actor>;

    public var meta(default, set): Null<MediaMetadata>;

    public var _changed: VoidSignal;
    public var _linked: Bool = false;
    private var _suspended: Bool = false;
    private var _susHasChanged: Bool = false;
}

class PatchTypeResolver {
    public function new() {
        //
    }

    public function resolveClass(name: String):Class<Dynamic> {
        if (name == 'pman.media.info.Mark') {
            name = 'pman.bg.media.Mark';
        }
        return Type.resolveClass( name );
    }

    public function resolveEnum(name: String):Enum<Dynamic> {
        if (name == 'pman.media.info.MarkType') {
            return pman.bg.media.Mark.MarkType;
        }
        return Type.resolveEnum( name );
    }
}
