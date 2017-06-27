package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;
import pman.async.tasks.LoadTrackData;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class TrackListDataLoader extends Task1 {
    /* Constructor Function */
    public function new():Void {
        super();
        tracks = new Array();
        datas = new Map();
    }

/* === Instance Methods === */

    /**
      * load the datas for all given Tracks
      */
    public function load(tracks:Array<Track>, ?done:Cb<TLDLResult>):Void {
        this.tracks = tracks;
        this.datas = new Map();
        var mic = new MediaIdCache();
        var cachedIds = mic.get(tracks.map.fn(_.uri));
        var numCached:Int = 0;
        for (t in tracks) {
            if (t.mediaId == null)
                t.mediaId = cachedIds[t.uri];
            if (t.mediaId != null)
                numCached++;
        }
        trace('$numCached media ids were loaded from cache');
        run(function(?error) {
            var result = {
                tracks: this.tracks,
                data: new Array()
            };
            var mset:Map<String,Int> = new Map();
            for (t in tracks) {
                result.data.push(datas[t.uri]);
                if (t.mediaId != null)
                    mset[t.uri] = t.mediaId;
            }
            mic.set( mset );
            if (done != null) {
                if (error != null)
                    done(error, null);
                else
                    done(null, result);
            }
        });
    }

    /**
      * execute [this] task
      */
    override function execute(done : VoidCb):Void {
        var actions = tracks.map.fn(t => gdt.bind(t, _));
        //actions.callEach( done );
        actions = actions.chunk( 20 ).map(function(list) {
            return list.callEach.bind( _ );
        });
        //actions.callEach( done );
        actions.series( done );
    }

    /**
      * load the TrackData for the given Track
      */
    private function gdt(track:Track, done:VoidCb):Void {
        var loadr = new LoadTrackData(track, BPlayerMain.instance.db);
        loadr.run(function(?error, ?data) {
            if (error != null) {
                if (Std.is(error, LoadTrackDataError)) {
                    var ltde:LoadTrackDataError = cast error;
                    switch ( ltde ) {
                        case EFileNonExistant( path ):
                            tracks.remove( track );
                            done();

                        default:
                            done( error );
                    }
                }
                else {
                    done( error );
                }
            }
            else {
                @:privateAccess track.data = data;
                datas[track.uri] = data;
                var tv = track.getView();
                if (tv != null) {
                    tv.update();
                }
                done();
            }
        });
    }

/* === Instance Fields === */

    private var tracks : Array<Track>;
    private var datas : Map<String, TrackData>;
}

typedef TLDLResult = {
    tracks : Array<Track>,
    data : Array<TrackData>
};
