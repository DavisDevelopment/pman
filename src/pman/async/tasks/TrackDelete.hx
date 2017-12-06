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

class TrackDelete extends Task1 {
    /* Constructor Function */
    public function new(t:Track, ms:MediaStore):Void {
        super();

        track = t;
        store = ms;
        itemIds = new Array();
        trackPaths = new Array();
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(done : VoidCb):Void {
        confirm_deletion(function(?e, ?confirmed:Bool) {
            if (confirmed == null) confirmed = false;
            if ( confirmed ) {
                var actions = [
                    obtain_deletion_queue,
                    dereference_track,
                    delete_track_files,
                    delete_track_rows
                ];
                actions.series(function(?err) {
                    if (err == null)
                        deleted = true;
                    done( err );
                });
            }
            else {
                done();
            }
        });
    }

    /**
      * compute what needs to be deleted
      */
    private function obtain_deletion_queue(done : VoidCb):Void {
        var tp = track.getFsPath();
        if (tp != null)
            trackPaths.push( tp );
        store.getRowByUri(track.uri, function(?error:Dynamic, ?row) {
            if (error != null) {
                done( error );
            }
            else if (row != null) {
                itemIds.push( row._id );
            }
            defer( done );
        });
    }

    /**
      * remove the Track completely from the Player/Session
      */
    private function dereference_track(done : VoidCb):Void {
        var s = track.session;
        function blurr(cb : VoidCb) {
            if (s.focusedTrack == track) {
                track.player.gotoNext({
                    attached: function() {
                        if (s.focusedTrack == track)
                            s.blur( track );
                        defer( cb );
                    }
                });
            }
            else cb();
        };

        blurr(function(?err) {
            if (err != null)
                done( err );

            s.playlist.remove( track );

            done();
        });
    }

    /**
      * move files associated with the Track to the Trash
      */
    private function delete_track_files(done : VoidCb):Void {
        for (path in trackPaths) {
            var movedToTrash = Shell.moveItemToTrash( path );
            if ( !movedToTrash ) {
                return done('Error: failed to move "$path" to Trash');
            }
        }
        done();
    }

    /**
      * delete database entries associated with the Track
      */
    private function delete_track_rows(done : VoidCb):Void {
        //inline function ift(s:String)
            //return itemIds.map.fn(id => store.deleteFrom.bind(s, id, _));
        //var actions = (ift('media_items').concat(ift('media_info')));
        //actions.series( done );
        done();
    }

    /**
      * confirm that the user does, in fact, wish to move the file to Trash
      */
    private function confirm_deletion(done : Cb<Bool>):Void {
        track.player.confirm('Are you sure you want to move this file to Trash?', function(status) {
            done(null, status);
        });
    }

/* === Instance Fields === */

    public var deleted : Bool = false;

    private var track : Track;
    private var store : MediaStore;
    private var itemIds : Array<String>;
    private var trackPaths : Array<Path>;
}
