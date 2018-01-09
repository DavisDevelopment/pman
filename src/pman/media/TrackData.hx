package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;
import tannus.nore.ORegEx;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.media.MediaType;
import pman.async.*;

import pman.media.info.*;
import pman.bg.media.Mark;
import pman.bg.media.Tag;

import haxe.Serializer;
import haxe.Unserializer;

import pman.Globals.*;

import Slambda.fn;
import tannus.node.Buffer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using pman.bg.DictTools;
using tannus.FunctionTools;

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
        channel = null;
        contentRating = 'NR';
    }

/* === Instance Methods === */

    /**
      * initialize [this] TrackData
      */
    public function initialize(db:PManDatabase, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        inline function step(x:VoidAsync) steps.push( x );

        //step(_parseTitle.bind(db, _));
        //step(save.bind(_, db.mediaStore));
        //TODO

        steps.series( done );
    }

    /**
      * parse additional data from [this]'s title
      */
    public function _parseTitle(db:PManDatabase, done:VoidCb):Void {
        var names:Set<String> = new Set();
        for (actor in actors) {
            names.push(actor.name.toLowerCase());
        }
        var allp = db.actorStore.allActors();
        allp.then(function(all) {
            var searchFor:Set<String> = new Set();
            var actord:Dict<String, Actor> = new Dict();
            for (actor in all) {
                var name = actor.name.toLowerCase();
                searchFor.push( name );
                actord[name] = actor;
            }
            searchFor = searchFor.difference( names );
            var found:Set<String> = new Set();
            var title:String = track.title.toLowerCase();
            for (name in searchFor) {
                if (title.has( name )) {
                    found.push( name );
                    actors.push(actord[name]);
                }
                //TODO also use EReg to check for name
            }
            trace(found.toArray());
            done();
        });
        allp.unless(done.raise());
    }

    /**
      * pull data from a MediaInfoRow
      */
    public function pullRaw(row:MediaRow, done:VoidCb, ?store:ActorStore):Void {
        if (store == null) {
            store = database.actorStore;
        }

        media_id = row._id;
        var d = row.data;
        views = d.views;
        starred = d.starred;
        rating = d.rating;
        description = d.description;

        if (d.meta != null) {
            meta = new MediaMetadata();
            meta.pullRaw( d.meta );
        }
        marks = d.marks.map( Unserializer.run );
        tags = d.tags.map( Unserializer.run );

        var steps:Array<VoidAsync> = new Array();

        // pull [actors]
        steps.push(function(next : VoidCb) {
            actors = new Array();
            if (d.actors == null || d.actors.length == 0) {
                next();
            }
            else {
                writeActors(d.actors, function(?error, ?al) {
                    next( error );
                });
            }
        });

        // execute [steps]
        steps.series(function(?error) {
            done( error );
        });
    }

    /**
      * convert [this] to a MediaInfoRow
      */
    public function toRaw():MediaRow {
        if (media_id == null) {
            //throw 'What the fuck?';
            //TODO
        }

        return {
            _id: media_id,
            uri: track.uri,
            data: {
                views: views,
                starred: starred,
                rating: rating,
                description: description,
                marks: marks.map( Serializer.run ),
                tags: tags.map( Serializer.run ),
                actors: actors.map.fn( _.name ),
                meta: (meta != null ? meta.toRaw() : null)
            }
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
        var db = BPlayerMain.instance.db;

        var steps:Array<VoidAsync> = [];
        steps.push(function(done : VoidCb) {
            var prom = store.putRow(toRaw());
            prom.then(function( row ) {
                pullRaw(row, done);
            });
            prom.unless(function( error ) {
                done( error );
            });
        });
        steps.series( complete );
    }

    /**
      *
      */
    public function sortMarks():Void {
        //marks.sort([x, y] => Reflect.compare(x.time, y.time));
        marks.sort((x, y) -> Reflect.compare(x.time, y.time));
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
        sortMarks();
    }

    /**
      * remove all marks of the given type
      */
    public function removeMarksOfType(mt : MarkType):Void {
        filterMarks.fn(!_.type.equals( mt ));
    }
    public function removeBeginMark():Void removeMarksOfType( Begin );
    public function removeEndMark():Void removeMarksOfType( End );
    public function removeLastTimeMark():Void removeMarksOfType( LastTime );

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
    public function getLastTime():Null<Float> {
        return _getTime( LastTime );
    }

    /**
      * get [this] Track's begin time
      */
    public function getBeginTime():Null<Float> {
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
    public function attachTag(tag : String):String {
        for (t in tags) {
            if (t == tag) {
                return t;
            }
        }
        tags.push( tag );
        return tag;
    }

    /**
      * attach a Tag to [this] as a String
      */
    public function addTag(tagName : String):String {
        return attachTag( tagName );
    }

    /**
      * select tag by oregex
      */
    public function selectTag(pattern : String):Null<String> {
        var reg:RegEx = new RegEx(new EReg(pattern, 'i'));
        return tags.firstMatch.fn(reg.match(_));
    }

    /**
      * checks for attached tag by given name
      */
    public function hasTag(name:String):Bool {
        for (t in tags)
            if (t == name)
                return true;
        return false;
    }

    /**
      * attach an Actor object to [this]
      */
    public function attachActor(actor : Actor):Void {
        if (!hasActor( actor.name )) {
            actors.push( actor );
        }
    }

    /**
      * add an Actor to [this] by name
      */
    public function addActor(name : String):Void {
        attachActor(new Actor(name, null));
    }

    /**
      * check whether the given Actor is attached to [this]
      */
    public function hasActor(name : String):Bool {
        for (actor in actors) {
            if (actor.name == name) {
                return true;
            }
        }
        return false;
    }

    /**
      * select a single Actor by predicate function
      */
    public function selectActor(predicate : Actor -> Bool):Maybe<Actor> {
        return actors.firstMatch( predicate );
    }

    /**
      * select a single Actor by ORegEx
      */
    public function oreselectActor(ore : String):Maybe<Actor> {
        return selectActor(untyped ORegEx.compile( ore ));
    }

    /**
      * detach an Actor from [this]
      */
    public function detachActor(actor : Actor):Void {
        var todel = [];
        for (a in actors) {
            if (a.equals( actor )) {
                todel.push( a );
            }
        }
        for (a in todel) {
            actors.remove( a );
        }
    }

    /**
      * remove an Actor from [this]
      */
    public function removeActor(name : String):Void {
        var actor = oreselectActor('[name="$name"]');
        if (actor == null) {
            return ;
        }
        else {
            detachActor( actor );
        }
    }

    /**
      * push an Actor onto [this]
      */
    public function pushActor(name:String, done:Cb<Actor>):Void {
        database.actorStore.cogActor(name, function(?error, ?actor) {
            if (error != null) {
                done(error, null);
            }
            else if (actor != null) {
                attachActor( actor );
                done(null, actor);
            }
        });
    }

    /**
      * push several Actors onto [this]
      */
    public function pushActors(names:Array<String>, done:Cb<Array<Actor>>):Void {
        database.actorStore.cogActorsFromNames(names, function(?error, ?al) {
            if (error != null) {
                return done(error, null);
            }
            else if (al != null) {
                for (a in al) {
                    attachActor( a );
                }
                done(null, al);
            }
        });
    }

    /**
      * set [this]'s 'actors' field
      */
    public function writeActors(names:Array<String>, done:Cb<Array<Actor>>):Void {
        var prevActors = actors.copy();
        actors = new Array();
        pushActors(names, done);
    }

    /**
      * edit [this] TrackData object
      */
    public function edit(action:TrackData->VoidCb->Void, done:VoidCb, _save:Bool=true):Void {
        var steps:Array<VoidAsync> = [action.bind(this, _)];
        if ( _save ) {
            steps.push(untyped save.bind(_, database.mediaStore));
        }
        steps.series( done );
    }

/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<String>;
    public var views : Int;
    public var starred : Bool;
    public var rating : Null<Float>;
    public var description : Null<String>;
    public var marks : Array<Mark>;
    public var tags : Array<String>;
    public var actors : Array<Actor>;
    public var channel : Null<String>;
    public var contentRating : Null<String>;

    public var meta : Null<MediaMetadata>;
}
