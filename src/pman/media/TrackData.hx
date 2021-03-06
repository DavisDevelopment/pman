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
import pman.async.tasks.TrackBatchCache;

import pman.media.info.*;
import pman.bg.media.Mark;
import pman.bg.media.Tag;
import pman.bg.media.MediaRow;
import pman.bg.media.MediaDataSource;
import pman.media.TrackData2;

import haxe.Serializer;
import haxe.Unserializer;
import Type.ValueType;

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

typedef TrackData = pman.media.TrackData2;

class OldTrackData {
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
    public function pullRaw(row:MediaRow, done:VoidCb, ?db:PManDatabase, ?cache:DataCache):Void {
        // ensure that we have a reference to [db]
        if (db == null) {
            db = PManDatabase.get();
        }

        // determine if [cache] was provided
        var hasCache:Bool = false;
        if (cache != null) {
            hasCache = true;
        }
        // and if not
        else {
            // load cache, and tail-call [pullRaw]
            (new TrackBatchCache( db ).get().unless(done.raise()).then(function(info) {
                pullRaw(row, done, db, info);
            }));
            return ;
        }


        // array to hold list of asynchronous actions to be taken
        var steps:Array<VoidAsync> = new Array();

        // shorthand reference to the 'data' property of the MediaRow
        var d:MediaDataRow = row.data;


        // copy over data which can be copied synchronously
        media_id = row._id;
        views = d.views;
        starred = d.starred;
        rating = d.rating;
        description = d.description;
        channel = d.channel;
        contentRating = d.contentRating;
        attrs = null;

        // if [d] has an 'attrs' property, pull that onto [this]
        if (d.attrs != null) {
            // ORegEx pattern for recognizing encoded attr values
            var pattern = ORegEx.compile('["$$$$encoded" => {Array}]');
            // function to transform [attr] values
            function transform_attr_value(av: Dynamic):Dynamic {
                // check type of [av]
                switch (Type.typeof( av )) {
                    // if [av] is an anonymous object type
                    case TObject, TUnknown:
                        // check for [pattern]
                        if (pattern.applyTo( av )) {
                            // extract 
                            var pair:Array<String> = Reflect.field(av, "$$encoded");
                            // decode encoded data
                            switch ( pair ) {
                                case ['json', s]:
                                    return haxe.Json.parse( s );

                                case ['haxe', s]:
                                    return Unserializer.run( s );

                                default:
                                    throw 'Error: Invalid "$$$$encoded" object';
                            }
                        }
                        else return av;

                    default:
                        return av;
                }
            }

            // convert Anon object to a Dict<String, Dynamic>
            attrs = d.attrs.toDict(null, transform_attr_value);
        }

        // pull metadata
        if (d.meta != null) {
            meta = new MediaMetadata();
            meta.pullRaw( d.meta );
        }

        // create a TypeResolver that will fix the broken reference to pman.media.info.Mark
        var ntr = (function() {
            var tr = Unserializer.DEFAULT_RESOLVER;
            return ({
                resolveClass: tr.resolveClass.wrap(function(_super, name:String) {
                    if (name == 'pman.media.info.Mark')
                        return cast Mark;
                    return _super( name );
                }),
                resolveEnum: tr.resolveEnum.wrap(function(_super, name:String) {
                    if (name == 'pman.media.info.MarkType')
                        return cast MarkType;
                    return _super( name );
                })
            });
        }());

        // a function that will decode encoded Mark instances,
        // whether they're encoded using the new format or the previous one
        function decode_mark(x: Dynamic):Mark {
            if ((x is String)) {
                var u = new Unserializer(cast x);
                u.setResolver( ntr );
                return u.unserialize();
            }
            else {
                return Mark.fromJsonMark(untyped x);
            }
        }

        // decode Mark instances
        marks = d.marks.map( decode_mark );

        // decode tags
        // detect when tags are stored in previous format, and decode them
        var ereg:EReg = ~/^y[0-9]+:/;
        steps.push(function(next: VoidCb) {
            // list to hold decoded Tags
            var _tags:Array<Tag> = new Array();

            // wrap [next], to set the [tags] field before returning
            next = next.wrap(function(_next, ?error) {
                this.tags = _tags.compact();
                _next( error );
            });

            // if [cache] was provided
            if ( hasCache ) {
                var name: String;
                // for each 'raw' tag
                for (rawTag in d.tags) {
                    name = rawTag;
                    // check if it is stored in a serialized manner, and if so
                    if (ereg.match( rawTag )) {
                        // unserialize it
                        var uname:String = Unserializer.run( rawTag );
                        // check that it is a String, and non-empty
                        if ((uname is String) && uname.hasContent()) {
                            name = uname;
                        }
                    }
                    // get cached 
                    if (cache.tags.exists( name )) {
                        _tags.push(cache.tags.get( name ));
                    }
                    else {
                        _tags.push(new Tag({
                            name: name
                        }));
                    }
                }
                next();
            }
            // if cache was not provided
            else {
                // create array to store async actions
                var tsteps:Array<VoidAsync> = new Array();
                // for every 'raw' tag
                for (rawTag in d.tags) {
                    // create variable to hold the name of the tag
                    var name:String = rawTag;
                    // if that name seems to be serialized
                    if (ereg.match( rawTag )) {
                        // unserialize it
                        name = Unserializer.run( rawTag );
                    }

                    // create async step that will..
                    tsteps.push(function(nxt) {
                        // fetch the 'row' for [this] tag from the database, simultaneously ensuring that one exists
                        db.tags.cogRow( name ).then(function(row) {
                            // push that 'row' onto the list of tags
                            _tags.push(new Tag( row ));

                            nxt();
                        }, nxt.raise());
                    });
                }
                // execute all async actions for tags
                tsteps.series( next );
            }
        });

        // pull [actors]
        steps.push(function(next : VoidCb) {
            // create new array to hold pulled actors
            actors = new Array();
            // if there's none to pull, just skip this step
            if (d.actors == null || d.actors.length == 0) {
                next();
            }
            // otherwise,
            else {
                // if cache was provided
                if ( hasCache ) {
                    // iterate over all actor-names in [row]
                    for (name in d.actors) {
                        // if there even exists a cached record of [name] actor
                        if (cache.actors.exists( name )) {
                            // use that one
                            actors.push(cache.actors[name]);
                        }
                        // otherwise,
                        else {
                            // create a new one
                            actors.push(new Actor({
                                name: name
                            }));
                        }
                    }
                    actors = actors.compact();
                    next();
                }
                else {
                    writeActors(d.actors, function(?error, ?al) {
                        next( error );
                    });
                }
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

        var row:MediaRow = ({
            _id: media_id,
            uri: track.uri,
            data: {
                views: views,
                starred: starred,
                rating: rating,
                description: description,
                attrs: (attrs != null ? attrs.toAnon(null, _encodeAttrVal) : null),
                marks: marks.map(m -> m.toJson()),
                tags: tags.map.fn( _.name ),
                actors: actors.map.fn( _.name ),
                meta: (meta != null ? meta.toRaw() : null)
            }
        });
        return row;
    }

    /**
      * encode an attribute value
      */
    private function _encodeAttrVal(value: Dynamic):Dynamic {
        //TODO actually encode values
        return value;
    }

    /**
      * push [this] TrackData to the database
      */
    public function save(?complete:VoidCb, ?db:PManDatabase):Void {
        if (complete == null)
            complete = VoidCb.noop;
        if (db == null) {
            db = PManDatabase.get();
        }

        var steps:Array<VoidAsync> = new Array();
        inline function step(f: VoidAsync) steps.push( f );

        // push [tags]
        step(function(next) {
            db.tags.cogRows(tags.map.fn(_.name)).then(function(x) next(), next.raise());
        });
        
        // push [actors]
        step(function(next) {
            db.actors.cogRowsFromNames(actors.map.fn(_.name)).then(x->next(), next.raise());
        });

        // push [this] to the database
        step(function(next) {
            var prom = db.media.putRow(toRaw());
            prom.then(function( row ) {
                pullRaw(row, next);
            }, next.raise());
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
                removeMarksOfType( mark.type );
                marks.push( mark );

            case Scene(type, name):
                removeMarksOfType( mark.type );
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
    public inline function addTag(tagName : String):Tag {
        trace('adding tag: $tagName');
        return attachTag(new Tag({name: tagName}));
    }

    /**
      * select tag by oregex
      */
    public function selectTag(pattern : String):Null<Tag> {
        var reg:RegEx = new RegEx(new EReg(pattern, 'i'));
        return tags.firstMatch.fn(reg.match( _.name ));
    }

    /**
      * checks for attached tag by given name
      */
    public function hasTag(name: String):Bool {
        for (t in tags)
            if (t.name == name)
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
        attachActor(new Actor({
            name: name
        }));
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
    //public function edit(action:TrackData->VoidCb->Void, done:VoidCb, _save:Bool=true):Void {
        //var steps:Array<VoidAsync> = [action.bind(this, _)];
        //if ( _save ) {
            //steps.push(untyped save.bind(_, null));
        //}
        //steps.series( done );
    //}

/* === Instance Fields === */

    public var track : Track;
    
    public var media_id : Null<String>;
    public var views : Int;
    public var starred : Bool;
    public var rating : Null<Float>;
    public var description : Null<String>;
    public var attrs : Dict<String, Dynamic>;
    public var marks : Array<Mark>;
    //public var tags : Array<String>;
    public var tags: Array<Tag>;
    public var actors : Array<Actor>;
    public var channel : Null<String>;
    public var contentRating : Null<String>;

    public var meta : Null<MediaMetadata>;

    private var source: Null<MediaDataSource>;
}

