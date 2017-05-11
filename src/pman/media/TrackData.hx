package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;
import tannus.nore.ORegEx;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.db.TagsStore;
import pman.media.MediaType;
import pman.async.*;
import pman.media.info.*;
import pman.media.info.Mark;

import haxe.Serializer;
import haxe.Unserializer;

import Slambda.fn;
import electron.Tools.defer;
import tannus.node.Buffer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class TrackData {
    /* Constructor Function */
    public function new(track : Track):Void {
        this.track = track;

        media_id = null;
        views = 0;
        starred = false;
        marks = new Array();
        tags = new Array();
        actors = new Array();
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
            tags: tags.map.fn( _.id ),
            actors: actors.map.fn( _.id ),
            meta: (meta != null ? meta.toRaw() : null)
        };
    }

    /**
      * push [this] TrackData to the database
      */
    public function save(?complete:VoidCb, ?store:MediaStore):Void {
        if (complete == null)
            complete = untyped fn(e=>trace(e));
        if (store == null) {
            store = BPlayerMain.instance.db.mediaStore;
        }
        var db = store.dbr;

        var steps:Array<VoidAsync> = [];

        // validate/assert/save tags
        steps.push(function(done:VoidCb) {
            var tsteps:Array<Async<TagRow>> = [];
            for (t in tags) {
                var tstep = db.tagsStore.cogTagRow.bind(t.name, t.type, _);
                tsteps.push( tstep );
            }
            tsteps.series(function(?err, ?rows) {
                if (err != null) {
                    return done( err );
                }
                else {
                    // once tags are saved, pull from the db-provided list of tag rows to 
                    // ensure that all attached tags have ids before saving
                    this.tags = rows.map.fn(Tag.fromRow(_));
                    done();
                }
            });
        });
        // validate/assert/save actors
        steps.push(function(done:VoidCb) {
            //TODO also push all actors
            defer(function() {
                done( null );
            });
        });
        steps.push(function(done : VoidCb) {
            var prom = store.putMediaInfoRow(toRaw());
            prom.then(function( row ) {
                pullRaw( row );

                if (done != null) {
                    done();
                }
            });
            prom.unless(function( error ) {
                done( error );
            });
        });
        steps.series( complete );
    }

    /**
      * add a new Mark to [this]
      */
    public function addMark(mark : Mark):Void {
        switch ( mark.type ) {
            case Begin, End, LastTime:
                //marks = marks.filter.fn(!_.type.equals( mark.type ));
                filterMarks.fn(!_.type.equals( mark.type ));
                marks.push( mark );

            case Named( name ):
                marks.push( mark );
        }
    }

    /**
      * remove all marks of the given type
      */
    public function removeMarksOfType(mt : MarkType):Void {
        filterMarks.fn(!_.type.equals( mt ));
    }
    public inline function removeBeginMark():Void removeMarksOfType( Begin );
    public inline function removeEndMark():Void removeMarksOfType( End );
    public inline function removeLastTimeMark():Void removeMarksOfType( LastTime );

    /**
      * remove a specific Mark
      */
    public function removeMark(mark : Mark):Void {
        filterMarks.fn(_ != mark);
    }

    /**
      * filter [marks]
      */
    public function filterMarks(f : Mark->Bool):Void {
        marks = marks.filter( f );
    }

    public function getMarkq(f : Mark->Bool):Null<Mark> {
        return marks.firstMatch( f );
    }
    public function getMarkByType(type : MarkType):Null<Mark> {
        return getMarkq.fn(_.type.equals( type ));
    }

    /**
      * get [this] Track's last time
      */
    public inline function getLastTime():Null<Float> {
        return _getTime( LastTime );
    }

    /**
      * get [this] Track's begin time
      */
    public inline function getBeginTime():Null<Float> {
        return _getTime( Begin );
    }

    /**
      * get [this] Track's end time
      */
    public inline function getEndTime():Null<Float> {
        return _getTime( End );
    }

    /**
      * set the time for the Mark of the given type
      */
    private function _setTime(type:MarkType, time:Float):Void {
        removeMarksOfType( type );
        addMark(new Mark(type, time));
    }

    /**
      * get the time for a Mark of the given type
      */
    private function _getTime(type:MarkType):Null<Float> {
        var m:Null<Mark> = getMarkByType( type );
        return (m != null ? m.time : null);
    }

    /**
      * set [this] Track's last time
      */
    public inline function setLastTime(time : Float):Void {
        _setTime(LastTime, time);
    }

    /**
      * set [this] Track's begin time
      */
    public inline function setBeginTime(time : Float):Void {
        _setTime(Begin, time);
    }

    /**
      * set [this] Track's end time
      */
    public inline function setEndTime(time : Float):Void {
        _setTime(End, time);
    }

    /**
      * attach a Tag instance to [this]
      */
    public function attachTag(tag : Tag):Tag {
        for (t in tags) {
            if (t.name == tag.name) {
                return t;
            }
        }
        tags.push( tag );
        return tag;
    }

    /**
      * attach a Tag to [this] as a String
      */
    public function addTag(tagName : String):Tag {
        return attachTag(new Tag( tagName ));
    }

    /**
      *
      */

    /**
      * attach an Actor instance to [this]
      */
    public function attachActor(actor : Actor):Actor {
        for (a in actors)
            if (a.name == actor.name)
                return a;
        actors.push( actor );
        return actor;
    }

    /**
      * add an Actor
      */
    public function addActor(name : String):Actor {
        return attachActor(new Actor( name ));
    }

    /**
      * select tag by oregex
      */
    public function selectTag(pattern : String):Null<Tag> {
        return tags.firstMatch(untyped ORegEx.compile( pattern ));
    }

    /**
      * select actor by oregex
      */
    public function selectActor(pattern : String):Null<Actor> {
        return actors.firstMatch(untyped ORegEx.compile( pattern ));
    }

    /**
      * checks for attached tag by given name
      */
    public function hasTag(name:String):Bool {
        for (t in tags)
            if (t.name == name)
                return true;
        return false;
    }

    /**
      * checks for attached actor by given name
      */
    public function hasActor(name:String):Bool {
        for (a in actors)
            if (a.name == name)
                return true;
        return false;
    }

/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<Int>;
    public var views : Int;
    public var starred : Bool;
    public var marks : Array<Mark>;
    public var tags : Array<Tag>;
    public var actors : Array<Actor>;

    public var meta : Null<MediaMetadata>;
}
