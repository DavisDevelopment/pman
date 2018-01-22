package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.core.exec.BatchExecutor;
import pman.bg.media.*;
import pman.bg.media.MediaData;
import pman.media.*;
import pman.edb.*;
import pman.bg.db.*;
import pman.async.*;

import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.core.ExecutorTools;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using pman.bg.DictTools;

class TrackBatchCache extends Task1 {
    public function new(db: PManDatabase):Void {
        super();

        this.db = db;
        actors = null;
        tags = null;
    }

/* === Instance Methods === */

    /**
      * run [this] Task
      */
    override function execute(done: VoidCb):Void {
        if (!isLoaded()) {
            load_cache( done );
        }
        else {
            defer(done.void());
        }
    }

    /**
      * 
      */
    public function get(?done: Cb<TrackBatchCacheContent>):Promise<TrackBatchCacheContent> {
        return Promise.create({
            run(function(?error) {
                if (error != null)
                    throw error;
                else {
                    return getContent();
                }
            });
        }).toAsync( done );
    }

    public function getContent():Null<TrackBatchCacheContent> {
        if (!isLoaded()) {
            return null;
        }
        else {
            return {
                actors: actors,
                tags: tags
            };
        }
    }

    private function load_cache(done: VoidCb):Void {
        [load_actor_cache, load_tag_cache].series( done );
    }

    /**
      * load and cache all actors
      */
    private function load_actor_cache(done: VoidCb):Void {
        this.actors = new Dict();
        db.actors.each(function(row: ActorRow) {
            var actor = new Actor( row );
            actors[actor.name] = actor;
            for (altName in actor.aliases) {
                actors[altName] = actor;
            }
        }, function(?error) {
            if (error != null) {
                //TODO handle error
            }
            done( error );
        });
    }

    /**
      * load and cache all tags
      */
    private function load_tag_cache(done: VoidCb):Void {
        this.tags = new Dict();
        var refactor:Array<TagRow> = new Array();
        var steps:Array<VoidAsync> = new Array();

        steps.push(function(next) {
            db.tags.each(function(row: TagRow) {
                var tag = new Tag( row );
                tags[tag.name] = tag;
            }, next);
        });

        var removes = [], creates = [];
        steps.push(function(next) {
            window.console.log(tags.toAnon());
            for (row in refactor) {
                removes.push(Reflect.copy( row ));
                row.name = Unserializer.run( row.name );
                Reflect.deleteField(row, '_id');
                creates.push( row );
            }

            var subs:Array<VoidAsync> = new Array();
            for (x in removes) {
                subs.push(function(next) {
                    db.tags.removeRow(x, next);
                });
            }
            for (x in creates) {
                if (!tags.exists( x.name ) && x != null && x.name.hasContent()) {
                    subs.push(function(next) {
                        db.tags.cogRow(x.name, function(?error, ?row) {
                            function okay() {
                                if (row != null) {
                                    var tag = new Tag( row );
                                    tags[tag.name] = tag;
                                }
                                next();
                            }

                            if (error != null) {
                                if (error.errorType != null && error.errorType == 'uniqueViolated') {
                                    okay();
                                }
                                else {
                                    throw error;
                                }
                            }
                            else {
                                okay();
                            }
                        });
                    });
                }
            }
            subs.series( next );
        });

        steps.series( done );
    }

    public inline function isLoaded():Bool {
        return (
            (actors != null) &&
            (tags != null)
        );
    }

/* === Instance Fields === */

    public var db: PManDatabase;
    public var actors: Sd<Actor>;
    public var tags: Sd<Tag>;
}

typedef TrackBatchCacheContent = {
    actors: Sd<Actor>,
    tags: Sd<Tag>
};

typedef Sd<T> = Dict<String, T>;
