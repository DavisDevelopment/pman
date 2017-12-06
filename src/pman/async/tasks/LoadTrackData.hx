package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.async.*;
import pman.media.info.*;

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

@:access( pman.media.Track )
class LoadTrackData extends Task2<TrackData> {
    /* Constructor Function */
    public function new(track:Track, db:PManDatabase):Void {
        super();

        this.track = track;
        this.db = db;
        this.store = db.mediaStore;
        this.data  = new TrackData( track );
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : Cb<TrackData>):Void {
        track._loadingData = true;
        [tryto_load, fill_missing_info, init_data].series(function(?error:Dynamic) {
            track._loadingData = false;
            if (error != null) {
                done(error, null);
            }
            else {
                done(null, data);
                track._dataLoaded.call( data );
            }
        });
    }

    /**
      * just initialize the TrackData
      */
    private function init_data(done: VoidCb):Void {
        data.initialize( done );
    }

    /**
      * attempt to load the data from the database
      */
    private function tryto_load(done : VoidCb):Void {
        switch ( track.source ) {
            case MediaSource.MSLocalPath( path ):
                if (!FileSystem.exists( path )) {
                    done(LoadTrackDataError.EFileNonExistant( path ));
                }
                else {
                    attempt_load( done );
                }

            default:
                attempt_load( done );
        }
    }

    /**
      * attempt to load the data from the database
      */
    private function attempt_load(done : VoidCb):Void {
        if (track.mediaId != null) {
            store.getRowById(track.mediaId, function(?error, ?irow) {
                if (error != null)
                    return done(error);
                data = new TrackData( track );
                data.pullRaw(irow, done);
            });
        }
        else {
            var uri:String = track.uri;
            store.getRowByUri(uri, function(?error:Dynamic, ?row:MediaRow) {
                if (error != null) {
                    return done( error );
                }
                else {
                    if (row == null) {
                        return create_new( done );
                    }
                    else {
                        track.mediaId = row._id;
                        data = new TrackData( track );
                        data.pullRaw(row, done);
                    }
                }
            });
        }
    }

    /**
      * create new TrackData
      */
    private function create_new(done : VoidCb):Void {
        data = new TrackData( track );
        loadMediaMetadata(function(?error, ?meta) {
            if (error != null) {
                return done( error );
            }
            else {
                data.meta = meta;
                push_data_to_db( done );
            }
        });
    }

    /**
      * push some data to the database
      */
    private function push_data_to_db(done : VoidCb):Void {
        var raw = data.toRaw();
        store.insertRow(raw, function(?error, ?row) {
            if (error != null) {
                return done( error );
            }
            else {
                data.pullRaw(row, done);
            }
        });
    }

    /**
      * attempt to fill in missing info and stuff
      */
    private function fill_missing_info(done : VoidCb):Void {
        if (data.meta == null || data.meta.isIncomplete()) {
            loadMediaMetadata(function(?error:Dynamic, ?meta) {
                if (error != null) {
                    return done( error );
                }
                else {
                    data.meta = meta;
                    done();
                }
            });
        }
        else {
            done();
        }
    }

    /**
      * get the media metadata
      */
    private function loadMediaMetadata(done : Cb<MediaMetadata>):Void {
        track.source.getMediaMetadata().then(done.yield()).unless(done.raise());
    }

/* === Instance Fields === */

    public var track : Track;
    public var db : PManDatabase;
    public var store : MediaStore;
    public var data : Null<TrackData>;
}

enum LoadTrackDataError {
    EFileNonExistant(path : Path);
}
