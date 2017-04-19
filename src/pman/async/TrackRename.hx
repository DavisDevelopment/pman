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
import electron.Tools.defer;
import gryffin.Tools.now;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class TrackRename extends Task {
    private var track : Track;
    private var store : MediaStore;
    private var name : Delta<Path>;

    /* Constructor Function */
    public function new(t:Track, ms:MediaStore, newName:Path):Void {
        super();

        track = t;
        store = ms;
        name = new Delta(newName, track.getFsPath());
    }

    override function action(done : Void->Void):Void {
        track.getData(function(i) {
            var stack = new AsyncStack();

            stack.push( repoint_track );
            stack.push( repoint_db_row );
            stack.push( rename_file );
            stack.push( refocus_track );

            stack.run( done );
        });
    }

    private function repoint_db_row(done : Void->Void):Void {
        var new_uri:String = 'file://'+(MediaSource.MSLocalPath( name.current ).mediaSourceToUri());
        var old_uri:String = 'file://'+(MediaSource.MSLocalPath( name.previous ).mediaSourceToUri());
        var p = store.cogMediaItemRow( new_uri );
        p.then(function( row ) {
            var prow = store.getMediaItemRowByUri( old_uri );
            prow.then(function( orow ) {
                var pp = store.getMediaInfoRow( orow.id );
                pp.then(function( infoRow ) {
                    infoRow.id = row.id;
                    trace( infoRow );
                    var irp = store.putMediaInfoRow( infoRow );
                    irp.then(function(infoRow) {
                        trace( infoRow );
                        defer( done );
                    });
                });
            });
        });
    }

    private function rename_file(done : Void->Void):Void {
        defer(function() {
            trace('renaming track from ${name.previous} to ${name.current}');
            FileSystem.rename(name.previous, name.current);
            defer( done );
        });
    }

    @:access( pman.media.MediaProvider )
    @:access( pman.media.LocalFileMediaProvider )
    @:access( pman.media.Track )
    private function repoint_track(done : Void->Void):Void {
        defer(function() {
            var newProvider = new LocalFileMediaProvider(new File( name.current ));
            focused = (track.session.focusedTrack == track);
            if ( focused )
                track.session.blur( track );

            track.data = null;
            track.provider = newProvider;

            done();
        });
    }
    private function refocus_track(done : Void->Void):Void {
        defer(function() {
            if ( focused ) {
                track.session.focus(track, done);
            }
            else defer( done );
        });
    }

    private var focused : Bool = false;
}
