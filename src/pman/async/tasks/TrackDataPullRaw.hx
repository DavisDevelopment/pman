package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.nore.ORegEx;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.async.*;
import pman.media.info.*;
import pman.bg.media.*;
import pman.bg.media.MediaDataSource;
import pman.bg.media.MediaRow;
import pman.bg.media.Mark;
import pman.media.TrackData2;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import Slambda.fn;

using tannus.math.TMath;
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

@:access( pman.media.TrackData2 )
class TrackDataPullRaw extends Task1 {
    /* Constructor Function */
    public function new(data:TrackData2, options:TrackDataPullRawOptions):Void {
        super();

        t = data;

        pullOptions( options );

        this.data = {
            row: row,
            initial: {},
            current: {

            }
        };
    }

/* === Instance Methods === */

    public static function pullRaw(data:TrackData2, row:MediaRow):Promise<MediaDataSource> {
        var start = now();
        return run_(data, {
            row: row,
            properties: TrackData2._all_,
            db: database
        }).always(function() {
            trace('took ${now() - start}ms to build a MediaDataSource from a MediaDataRow');
        });
    }

    public static function run_(data:TrackData2, options:TrackDataPullRawOptions):Promise<MediaDataSource> {
        var x = new TrackDataPullRaw(data, options);
        return x.pull();
    }

    /**
      * load source
      */
    public function pull():Promise<MediaDataSource> {
        return new Promise<MediaDataSource>(function(yes, no) {
            run(function(?error) {
                if (error != null) {
                    no( error );
                }
                else {
                    var source:MediaDataSource = TrackData2.createMediaDataSource(TrackData2.getMediaDataSourceDeclFromPropertyList( properties ), data);
                    yes( source );
                }
            });
        });
    }

    /**
      * execute [this] method
      */
    override function execute(done: VoidCb):Void {
        // build list of tasks
        var steps:Array<VoidAsync> = [
            ensure_cache,
            pull_sync_fields,
            pull_meta,
            pull_marks,
            pull_attrs,
            pull_tags,
            pull_actors,
            build_initial_data
        ];

        // execute those tasks
        steps.series( done );
    }

    /**
      * ensure that [cache] exists before data loading
      */
    private function ensure_cache(next: VoidCb):Void {
        if (cache != null) {
            next();
        }
        else {
            TrackBatchCache.create().then(function(cache) {
                this.cache = cache;
                next();
            }, next.raise());
        }
    }

    /**
      * build out the proper value for data.initial
      */
    private function build_initial_data(next: VoidCb):Void {
        data.initial = _.clone( data.current );
        var i:NullableMediaDataState = data.initial;

        // copy 'meta' field
        if (has( 'meta' ) && i.meta != null) {
            i.meta = i.meta.clone();
        }

        // copy 'attrs' field
        if (has( 'attrs' ) && i.attrs != null) {
            i.attrs = i.attrs.copy();
        }

        // copy 'tags' field
        if (has( 'tags' ) && i.tags != null) {
            i.tags = i.tags.map.fn(_.clone());
        }

        // copy 'actors' field
        if (has('actors') && i.actors != null) {
            i.actors = i.actors.map.fn(_.clone());
        } 

        // copy 'marks' field
        if (has('marks') && i.marks != null) {
            i.marks = i.marks.map(mark->mark.clone());
        }

        next();
    }

    /**
      * pull marks
      */
    private function pull_marks(next: VoidCb):Void {
        if (has('marks') && d.marks != null) {
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
            oc.marks = d.marks.map( decode_mark );
            next();
        }
        else {
            return next();
        }
    }

    /**
      * pull the meta field
      */
    private function pull_meta(next: VoidCb):Void {
        // pull metadata
        if (has('meta') && d.meta != null) {
            var meta = new MediaMetadata();
            meta.pullRaw( d.meta );
            oc.meta = meta;
            next();
        }
        else {
            return next();
        }
    }

    /**
      * pull the actors field
      */
    private function pull_actors(next: VoidCb):Void {
        if (!has( 'actors' )) {
            return next();
        }
        else {
            // create new array to hold pulled actors
            var actors = new Array();
            // if there's none to pull, just skip this step
            if (d.actors == null || d.actors.length == 0) {
                oc.actors = new Array();
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
                    oc.actors = actors.compact();
                    next();
                }
                else {
                    next('Error: Cache missing');
                }
            }
        }
    }

    /**
      * pull the tags field
      */
    private function pull_tags(next: VoidCb):Void {
        if (has( 'tags' )) {
            // decode tags
            // detect when tags are stored in previous format, and decode them
            var ereg:EReg = ~/^y[0-9]+:/;
            // list to hold decoded Tags
            var _tags:Array<Tag> = new Array();

            // wrap [next], to set the [tags] field before returning
            next = next.wrap(function(_next, ?error) {
                oc.tags = _tags.compact();
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
        }
        else {
            return next();
        }
    }

    /**
      * pull the 'attrs' field
      */
    private function pull_attrs(next: VoidCb):Void {
        // if 'attrs' property is absent, move on
        if (!has( 'attrs' )) {
            return next();
        }
        else {
            // if 'attrs' property exists
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
                oc.attrs = d.attrs.toDict(null, transform_attr_value);

                // move on
                return next();
            }
            else {
                // move on
                return next();
            }
        }
    }

    /**
      * copy over the fields which can be copied syncronously
      */
    private function pull_sync_fields(next: VoidCb):Void {
        t.media_id = row._id;

        if (has( 'views' ))
            oc.views = d.views;

        if (has( 'starred' ))
            oc.starred = d.starred;

        if (has( 'rating' ))
            oc.rating = d.rating;

        if (has( 'description' ))
            oc.description = d.description;

        if (has( 'channel' ))
            oc.channel = d.channel;

        if (has( 'contentRating' ))
            oc.contentRating = d.contentRating;

        next();
    }

    /**
      * merge [options] onto [this]
      */
    private function pullOptions(options: TrackDataPullRawOptions):Void {
        row = options.row;
        properties = (options.properties != null ? options.properties : TrackData2._all_);
        db = (options.db != null ? options.db : database);
        cache = options.cache;
    }

    /**
      * check for a property
      */
    private inline function has(name: String):Bool return properties.has( name );

/* === Computed Instance Fields === */

    private var c(get, never):Object;
    private inline function get_c():Object return data.current;

    private var oc(get, never):NullableMediaDataState;
    private inline function get_oc() return data.current;

    private var d(get, never):MediaDataRow;
    private inline function get_d() return row.data;

    private var hasCache(get, never):Bool;
    private inline function get_hasCache():Bool return (cache != null);

/* === Instance Fields === */

    public var t: TrackData2;
    public var row: MediaRow;
    public var properties: Array<String>;
    public var db: PManDatabase;
    public var cache: Null<DataCache>;
    public var data: MediaDataSourceState;
}

typedef TrackDataPullRawOptions = {
    row: MediaRow,
    ?properties:Array<String>,
    ?db: PManDatabase,
    ?cache: DataCache
};
