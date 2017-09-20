package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.media.info.Bundles;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.edb.Modification;
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
                } 
                else {
                    return done( error );
                }
            }
            else {
                ([
                    repoint_track,
                    repoint_db_row,
                    rename_file,
                    rename_bundle,
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
            if ( focused ) {
                track.session.blur( track );
            }

            // the Track's previous uri
            var oldUri = track.uri;

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

        store._mutate(fn(_.eq('_id', track.mediaId)), function(m:Modification) {
            m.set('uri', new_uri);
        }, null, function(?error, ?row) {
            if (error != null)
                return done( error );
            else if (row != null) {
                //TODO
                done();
            }
        });
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
      * rename the bundle folder
      */
    private function rename_bundle(done : VoidCb):Void {
        var oldBundlePath = Bundles.getBundlePath(new Path(name.previous).name);
        var newBundlePath = Bundles.getBundlePath(new Path(name.current).name);
        try {
            FileSystem.rename(oldBundlePath, newBundlePath);
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
        var uri = fn(p => ('file://'+(MediaSource.MSLocalPath(p).mediaSourceToUri())));
        var oldUri = uri( name.previous );
        defer(function() {
            // relink the Track's view to it
            var plv = track.player.page.playlistView;
            if (plv != null) {
                // get reference to the PlaylistView's internal cache of TrackViews
                var tc = @:privateAccess plv._tc;
                var tv = tc[oldUri];
                if (tv != null) {
                    tc.remove( oldUri );
                    tc[track.uri] = tv;
                }
                tv.update();
            }
            defer( done );
        });
    }

    /**
      * delete all items in the database that have been dereferenced by [this] action
      */
    private function sanitize_db(done : VoidCb):Void {
        //var deletes = [
            //store.deleteFrom.bind('media_items', toDelete[0]),
            //store.deleteFrom.bind('media_info', toDelete[1])
        //];
        //deletes.callEach( done );
        done();
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
