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
        run(function(?error) {
            var result = {
                tracks: this.tracks,
                data: new Array()
            };
            for (t in tracks) {
                result.data.push(datas[t.uri]);
            }
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
        actions.callEach( done );
    }

    /**
      * load the TrackData for the given Track
      */
    private function gdt(track:Track, done:VoidCb):Void {
        var loadr = new LoadTrackData(track, BPlayerMain.instance.db.mediaStore);
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
