package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;
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

class TrackRename extends Task1 {
    /* Constructor Function */
    public function new(t:Track, ms:MediaStore):Void {
        super();

        track = t;
        store = ms;
        toDelete = new Array();
        renamed = null;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : VoidCb):Void {
        get_newpath(function(?error : Dynamic) {
            if (error != null) {
                if ((error is CancelTrackRename)) {
                    renamed = null;
                    return done();
                } else return done( error );
            }
            else {
                ([
                    repoint_track,
                    repoint_db_row,
                    rename_file,
                    reattach_track,
                    update_track_views,
                    sanitize_db
                ].series( done ));
            }
        });
    }

    /**
      * obtain the desired new path from the user
      */
    private function get_newpath(done : VoidCb):Void {
        var path = track.getFsPath();
        // open the Prompt
        var box = track.player.prompt('rename track', null, path, function(line : Null<String>) {
            // if no input was provided
            if (line == null) {
                // relay task cancellation to [execute]
                return done( CancelTrackRename.EmptyInput );
            }
            // if valid input was provided
            else {
                // build Path from String input
                var newPath:Path = (new Path( line ).normalize());
                // check whether the referenced Path already exists, and if so
                if (FileSystem.exists( newPath )) {
                    // relay task cancellation to [execute]
                    return done( CancelTrackRename.AlreadyExists );
                }
                // if path does not exist, then we're all clear
                else {
                    // assign value to [name]
                    name = new Delta(newPath, path);
                    // assign value to [renamed]
                    renamed = name.current;
                    // report completion of task
                    return done();
                }
            }
        });

        // get some strings to work with
        var total:String = path.toString();
        var name:String = path.name, ext:String = path.extension;
        // select entirety of text-input
        box.select();
        // calculate range to select
        var i = [total.indexOf( name ), total.indexOf('.$ext')];
        // select that range
        box.selectRange(i[0], i[1]);
    }

    /**
      * alter [track]'s fields inplace to point it to the media's new Path
      */
    @:access( pman.media.MediaProvider )
    @:access( pman.media.LocalFileMediaProvider )
    @:access( pman.media.Track )
    private function repoint_track(done : VoidCb):Void {
        defer(function() {
            // create new MediaProvider that references file's new Path
            var newProvider = new LocalFileMediaProvider(new File( name.current ));
            // cache whether the Track is focused
            focused = (track.session.focusedTrack == track);
            // defocus the Track if necessary
            if ( focused )
                track.session.blur( track );

            // nullify track's data
            track.data = null;
            // reassign track's provider
            track.provider = newProvider;

            done();
        });
    }

    /**
      * modify the database such that all metadata associated with the media's current path will be associated with its new one
      */
    private function repoint_db_row(done : VoidCb):Void {
        var raise = done.raise();
        var uri = fn(p => ('file://'+(MediaSource.MSLocalPath(p).mediaSourceToUri())));
        var new_uri:String = uri( name.current );
        var old_uri:String = uri( name.previous );

        // new media item row promise
        var newmirp = store.cogMediaItemRow( new_uri );
        // when new row is obtained from the db
        newmirp.then(function(newMediaItemRow) {
            // old row promise
            var orp = store.getMediaItemRowByUri( old_uri );
            // when old row has been retrieved
            orp.then(function(oldMediaItemRow) {
                // queue the old item_row for deletion
                toDelete.push( oldMediaItemRow.id );
                // request info_row for old path
                var oirp = store.getMediaInfoRow( oldMediaItemRow.id );
                // when/if info_row is retrieved
                oirp.then(function( infoRow ) {
                    // queue old info_row for deletion
                    toDelete.push( infoRow.id );
                    // reassign its [id] field to match the id of our new media_item row
                    infoRow.id = newMediaItemRow.id;
                    // push that shit onto the database
                    var nirp = store.putMediaInfoRow( infoRow );
                    // when we get the row object back from the database
                    nirp.then(function(newInfoRow) {
                        // print it to the console
                        trace(newInfoRow);
                        // declare this step complete
                        defer(done.void());
                    });
                    // handle errors pushing info_row
                    nirp.unless( raise );
                });
                // handle errors loading info_row
                oirp.unless( raise );
            });
            // handle errors loading old media_item row
            orp.unless( raise );
        });
        // handle errors pushing new media_item row
        newmirp.unless( raise );
    }

    /**
      * actually alter the file's path in the filesystem
      */
    private function rename_file(done : VoidCb):Void {
        try {
            // actually change file's path
            FileSystem.rename(name.previous, name.current);
            // declare completion
            defer(done.void());
        }
        catch (error : Dynamic) {
            done( error );
        }
    }

    /**
      * reattach newly modified Track to the Player
      */
    private function reattach_track(done : VoidCb):Void {
        defer(function() {
            if ( focused ) {
                track.session.focus(track, done.void());
            }
            else defer(done.void());
        });
    }

    /**
      * update any/all views displaying Track information
      */
    private function update_track_views(done : VoidCb):Void {
        defer(function() {
            var tv = track.getView();
            if (tv != null) {
                tv.update();
            }
            defer( done );
        });
    }

    /**
      * delete all items in the database that have been dereferenced by [this] action
      */
    private function sanitize_db(done : VoidCb):Void {
        var deletes = [
            store.deleteFrom.bind('media_items', toDelete[0]),
            store.deleteFrom.bind('media_info', toDelete[1])
        ];
        deletes.callEach( done );
    }

/* === Instance Fields === */

    public var renamed:Maybe<Path>;

    private var track:Track;
    private var store:MediaStore;
    private var name:Delta<Path>;
    private var focused:Bool = false;
    private var toDelete:Array<Int>;
}

enum CancelTrackRename {
    EmptyInput;
    AlreadyExists;
}
