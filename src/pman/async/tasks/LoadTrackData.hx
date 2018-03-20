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
import pman.bg.media.MediaDataSource;

import haxe.Unserializer;

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
using pman.bg.DictTools;

@:access( pman.media.Track )
@:access( pman.media.TrackData2 )
class LoadTrackData extends Task2<TrackData> {
    /* Constructor Function */
    public function new(track:Track, db:PManDatabase):Void {
        super();

        this.track = track;
        this.db = db;
        this.store = db.mediaStore;
        this.properties = TrackData._all_.copy();
        this.data  = new TrackData( track );
        this.cache = new TrackBatchCache( db );
    }

/* === Instance Methods === */

    /**
      * set [this]'s property list
      */
    public inline function setPropertyList(props: Array<String>):LoadTrackData {
        properties = props;
        return this;
    }

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
        data.initialize(db, done);
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
                pull_raw(irow, data, done);
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
                        pull_raw(row, data, done);
                    }
                }
            });
        }
    }

    /**
      * create new TrackData
      */
    private function create_new(done : VoidCb):Void {
        data = new TrackData(track, Create({
            initial: {},
            current: {}
        }));

        loadMediaMetadata(function(?error, ?meta) {
            if (error != null) {
                return done( error );
            }
            else {
                data.meta = meta;
                trace( data.meta );
                push_data_to_db( done );
            }
        });
    }

    /**
      * push some data to the database
      */
    private function push_data_to_db(done : VoidCb):Void {
        // create the MediaRow object
        var raw:MediaRow = data.toRaw();

        // push it to the database
        store.insertRow(raw, function(?error, ?row) {
            if (error != null) {
                return done( error );
            }
            else {
                pull_raw(row, data, done);
            }
        });
    }

    /**
      * attempt to fill in missing info and stuff
      */
    private function fill_missing_info(done : VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        if (data.meta == null || data.meta.isIncomplete()) {
            steps.push(function(next) {
                loadMediaMetadata(function(?error:Dynamic, ?meta) {
                    if (error != null) {
                        return next( error );
                    }
                    else {
                        data.meta = meta;
                        next();
                    }
                });
            });
        }
        steps.push(function(next) {
            //FIXME skip over this step
            return next();
            var filler = new TrackDataAutoFill(track, data);
            filler.giveCache( cache );
            filler.run( next );
        });
        steps.series( done );
    }

    /**
      * get the media metadata
      */
    private function loadMediaMetadata(done : Cb<MediaMetadata>):Void {
        track.source.getMediaMetadata().then(done.yield()).unless(done.raise());
    }

    /**
      * pull raw
      */
    private function pull_raw(row:MediaRow, data:TrackData, done:VoidCb):Void {
        cache.get().unless(done.raise()).then(function(info) {
            data.pullSource(row, src_decl(), done, db, info);
            //data.pullRaw(row, done, db, info);
        });
    }

    /**
      * get the MediaDataSourceDecl for [properties]
      */
    private function src_decl():MediaDataSourceDecl {
        if (data.source.match(Create(_))) {
            return Complete;
        }
        return TrackData.getMediaDataSourceDeclFromPropertyList( properties );
    }

/* === Instance Fields === */

    public var track : Track;
    public var db : PManDatabase;
    public var store : MediaStore;
    public var properties: Array<String>;
    public var data : Null<TrackData>;
    public var cache: TrackBatchCache;
}

enum LoadTrackDataError {
    EFileNonExistant(path : Path);
}
