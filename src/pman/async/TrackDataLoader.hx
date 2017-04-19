package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.node.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;

import Std.*;
import tannus.math.TMath.*;
import js.Browser.window;
import electron.Tools.defer;
import gryffin.Tools.now;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class TrackDataLoader extends StandardTask<String, TrackData> {
    /* Constructor Function */
    public function new(track:Track, store:MediaStore):Void {
        super();

        this.track = track;
        this.store = store;

        status = 'beginning load...';
        result = new TrackData( track );
    }

/* === Instance Methods === */

    /**
      * shorthand to load the shit
      */
    public function load():Promise<TrackData> {
        return Promise.create({
            // catch errors
            failureEvent.once(function(error) {
                throw error;
            });

            // perform [this] Task
            perform(function() {
                return data;
            });
        });
    }

    /**
      * primary action
      */
    override function action(done : Void->Void):Void {
        var stack = new AsyncStack();
        status = 'building action stack';

        stack.push( attempt_load );
        stack.push( fill_missing_info );

        status = 'running action stack';
        stack.run(function() {
            status = 'load complete!';
            done();
        });
    }

    /**
      * attempt to load the data from the database
      */
    private function attempt_load(next : Void->Void):Void {
        status = 'attempting to load existing data';
        var p = store.getMediaItemRowByUri( track.uri );
        p.then(function( row ) {
            if (row == null) {
                create_new( next );
            }
            else {
                status = 'media id retrieved';
                var p = store.getMediaInfoRow( row.id );
                p.then(function( irow ) {
                    data.pullRaw( irow );
                    progress( 75 );
                    next();
                });
                p.unless(function( error ) {
                    throw error;
                });
            }
        });
        p.unless(function( error ) {
            throw error;
        });
    }

    /**
      * fill in missing info
      */
    private function fill_missing_info(next : Void->Void):Void {
        status = 'completing metadata';
        // if any data is missing from the TrackData's 'meta' field
        if (data.meta == null || data.meta.isIncomplete()) {
            // reload the entirety of the media metadata and reassign said field
            loadMediaMetadata(function( md ) {
                data.meta = md;
                status = 'metadata complete';
                progress( 25 );
                next();
            });
        }
        else {
            defer( next );
        }
    }

    /**
      * build new data from scratch
      */
    private function create_new(next : Void->Void):Void {
        status = 'creating new media_info row';
        // create new row for the media item in question
        var itemRowp = store.newMediaItemRowFor( track.uri );
        // once new row has been created
        itemRowp.then(function( itemRow ) {
            status = 'row created';
            progress( 25 );
            // copy the 'media id' onto the TrackData
            data.media_id = itemRow.id;
            // get the media's metadata
            status = 'loading row as media metadata';
            loadMediaMetadata(function( md ) {
                // put that metadata on the track data
                data.meta = md;
                status = 'row loaded as media metadata';
                progress( 25 );
                
                // push the newly created data onto the database
                push_data_to_db( next );
            });
        });
        itemRowp.unless(function( error ) {
            if (error.name == 'ConstraintError') {
                defer(function() {
                    attempt_load( next );
                });
            }
            else throw error;
        });
    }

    /**
      * push the data onto the database
      */
    private function push_data_to_db(next : Void->Void):Void {
        status = 'pushing row onto database..';
        var raw:MediaInfoRow = data.toRaw();
        store.putMediaInfoRow_(raw, function(error : Null<Dynamic>) {
            if (error != null) {
                throw error;
            }
            status = 'row written to database';
            progress( 25 );
            next();
        });
    }

    /**
      * load the MediaMetadata for the given Track
      */
    private function loadMediaMetadata(callback : Null<MediaMetadata>->Void):Void {
        var metap = track.uri.uriToMediaSource().getMediaMetadata();
        metap.then(function( meta ) {
            callback( meta );
        });
        metap.unless(function(error) {
            throw error;
        });
    }

/* === Computed Instance Fields === */

    public var data(get, set):TrackData;
    private inline function get_data() return result;
    private inline function set_data(v) return (result = v);

/* === Instance Fields === */

    public var track : Track;
    public var store : MediaStore;
}
