package pman.bg.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import ffmpeg.Fluent;

import pman.bg.Dirs;
import pman.bg.db.*;
import pman.bg.media.*;
import pman.bg.media.Media;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;

import Slambda.fn;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class LoadMediaData extends Task2<MediaData> {
    /* Constructor Function */
    public function new(uri:String, db:Database):Void {
        super();

        //this.media = media;
        this.mediaUri = uri.toUri();
        this.mediaSource = this.mediaUri.toMediaSource();
        this.db = db;
        this.data = new MediaData();
    }

/* === Instance Methods === */

    /**
      * execute [this]
      */
    override function execute(done: Cb<MediaData>):Void {
        trace('Starting LoadMediaData');
        done = done.wrap(function(dun, ?error, ?data) {
            if (error != null)
                trace('LoadMediaData has failed');
            else
                trace('LoadMediaData completed successfully');
            dun(error, data);
        });

        [tryto_load, fill_missing_info].series(function(?error) {
            if (error != null) {
                done(error, null);
            }
            else {
                done(null, data);
            }
        });
    }

    private function tryto_load(done: VoidCb):Void {
        switch ( mediaSource ) {
            case MediaSource.MSLocalPath( path ):
                if (!Fs.exists( path )) {
                    done('Error: File "$path" does not exist');
                }
                else {
                    attempt_load( done );
                }

            default:
                attempt_load( done );
        }
    }

    /**
      * attempt to load the MediaRow
      */
    private function attempt_load(done: VoidCb):Void {
        trace('attempting to load MediaRow document');
        store.cogRow(mediaUri.toUri(), function(?error:Dynamic, ?row:MediaRow) {
            if (error != null) {
                return done( error );
            }
            else {
                if (row == null) {
                    return create_new( done );
                }
                else {
                    trace('LOADED: MediaRow document');
                    trace( row );
                    data.pullMediaRow(row, done);
                }
            }
        });
    }

    /**
      * 
      */
    private function create_new(done: VoidCb):Void {
        data = new MediaData();
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
      * push new data to the database
      */
    private function push_data_to_db(done: VoidCb):Void {
        var raw = data.toRow();
        var mraw:MediaRow = {
            uri: mediaUri,
            data: raw
        };

        store.insertRow(mraw, function(?error, ?row) {
            if (error != null) {
                return done( error );
            }
            else {
                data.pullMediaRow(row, done);
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
      * load the Media's metadata
      */
    private function loadMediaMetadata(done: Cb<MediaMetadata>):Void {
        switch ( mediaSource ) {
            case MediaSource.MSLocalPath(path):
                LoadMediaMetadata.load( path ).toAsync( done );

            default:
                done('Betty', null);
        }
    }

/* === Computed Instance Fields === */

    private var store(get, never):MediaTable;
    private inline function get_store() return db.media;

/* === Instance Fields === */

    //public var media: Media;
    public var mediaUri: String;
    public var mediaSource: MediaSource;
    public var db: Database;
    public var data: Null<MediaData>;
}
