package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.core.exec.BatchExecutor;
import pman.bg.media.*;
import pman.bg.media.Mark;
import pman.bg.media.MediaData;
import pman.media.*;
import pman.edb.*;
import pman.bg.db.*;
import pman.async.*;
import pman.async.tasks.TrackBatchCache;
import pman.async.tasks.TrackBatchCache.TrackBatchCacheContent as Info;

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

class TrackDataAutoFill extends Task1 {
    /* Constructor Function */
    public function new(track:Track, data:TrackData):Void {
        super();

        this.track = track;
        this.data = data;
        this.cache = new TrackBatchCache( bpmain.db );
    }

/* === Instance Methods === */

    /**
      * execute [this]
      */
    override function execute(done: VoidCb):Void {
        cache.get(function(?error, ?info) {
            if (error != null) {
                done( error );
            }
            else {
                fields = text_info().map.fn(_.toLowerCase());
                var funcs = [
                    auto_actors,
                    auto_tags
                ].map(x -> x.bind(info, _));
                funcs.series(function(?error) {
                    if (error != null) {
                        done( error );
                    }
                    else {
                        data.save(done, cache.db);
                    }
                });
            }
        });
    }

    /**
      * automatically tag track with Actors, where possible
      */
    private function auto_actors(info:Info, done:VoidCb):Void {
        for (star in info.actors) {
            if (data.actors.has( star )) {
                continue;
            }

            var name = star.name.toLowerCase();
            for (txt in fields) {
                if (txt.has( name )) {
                    data.actors.push( star );
                }
            }
        }
        
        done();
    }

    /**
      * automatically attach tags to track, where possible
      */
    private function auto_tags(info:Info, done:VoidCb):Void {
       for (tag in info.tags) {
           if (data.tags.has( tag )) {
               continue;
           }

           var tn = tag.name.toLowerCase();
           for (txt in fields) {
               if (txt.has( tn )) {
                   data.tags.push( tag );
               }
           }
       }
    
       done();
    }

    /**
      * extract a list of track-related Strings which may be used for auto-tagging
      */
    private inline function text_info():Array<String> {
        var results:Array<String> = [track.title, track.uri];
        inline function tryPush(x: String) {
            if (x.hasContent()) {
                results.push( x );
            }
        }

        tryPush( data.description );
        tryPush( data.channel );

        for (mark in data.marks) {
            switch ( mark.type ) {
                case MarkType.Named(markName):
                    tryPush( markName );

                default: null;
            }
        }

        return results;
    }

    /**
      * provide cache data to [this] Task
      */
    public function giveCache(cache: TrackBatchCache):Void {
        this.cache = cache;
    }

/* === Instance Fields === */

    public var track: Track;
    public var data: TrackData;
    
    private var cache: TrackBatchCache;
    private var fields: Array<String>;
}
