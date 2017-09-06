package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.core.*;
import pman.media.*;
import pman.async.*;
import pman.db.*;

import tannus.math.TMath.*;
import foundation.Tools.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;
using pman.async.Asyncs;

@:access( pman.core.Player )
class PlayerStartup extends Task1 {
    /* Constructor Function */
    public function new(p : Player):Void {
        super();

        player = p;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(complete : VoidCb):Void {
        [
            restore_playbackProperties,
            startup_loads
        ]
        .series( complete );
    }

    /**
      * restore playback properties if there are any saved
      */
    private function restore_playbackProperties(done : VoidCb):Void {
        defer(function() {
            try {
                player.session.loadPlaybackSettings();
                done();
            }
            catch (err:Dynamic) {
                done( err );
            }
        });
    }

    /**
      * perform startup media loading
      */
    private function startup_loads(done : VoidCb):Void {
        var slSrc = player.flag( 'src' );
        if (slSrc == null) {
            startup_load_session( done );
        }
        else {
            var src:String = Std.string( slSrc );
            switch ( src ) {
                case 'session', 'default':
                    startup_load_session( done );

                case 'cli', 'command-line-input':
                    VoidAsyncs.series([startup_load_session, startup_load_cli], done);

                default:
                    done('Error: Invalid src flag "$src"');
            }
        }
    }

    /**
      * perform session-loading startup tasks
      */
    private function startup_load_session(done : VoidCb):Void {
        var l = (player.app.db.preferences.autoRestore ? startup_load_default_session : startup_confirm_load_session);
        l( done );        
    }

    /**
      * load default saved player session
      */
    private function startup_load_default_session(done : VoidCb):Void {
        player.session.restore(function(?error) {
            done.forward( error );
            declareReady( done );
        });
    }

    /**
      * prompt the user whether to restore session
      */
    private function startup_confirm_load_session(done : VoidCb):Void {
        if (player.session.hasSavedState()) {
            declareReady(function(?err) {
                done.forward( err );
                player.confirm('Restore Previous Session?', function(restore : Bool) {
                    if ( restore ) {
                        startup_load_default_session( done );
                    }
                    else {
                        defer(done.void());
                    }
                });
            });
        }
        else {
            declareReady( done );
        }
    }

    /**
      * load media from command-line input
      */
    private function startup_load_cli(done : VoidCb):Void {
        var paths = expand_paths( player.app.launchInfo.paths );
        var tracks = resolve_tracks( paths );
        declareReady(function(?err) {
            done.forward( err );
            if (!(player.session.activeTab != null && player.session.activeTab.playlist.length > 0)) {
                var newTabIndex = player.session.newTab();
                player.session.setTab( newTabIndex );
            }
            defer(function() {
                player.addItemList(tracks, function() {
                    done();
                });
            });
        });
    }

    /**
      * convert list of arbitrary paths to a list of paths that all point to openable media files that actually exist
      */
    private inline function expand_paths(a : Array<Path>):Array<Path> {
        return new PathListConverter().convert(a.filter.fn(Fs.exists(_)));
    }
    private function resolve_tracks(a : Array<Path>):Array<Track> {
        return new FileListConverter().convert(a.map.fn(new File( _ ))).toArray();
    }

    /**
      * announce Player's readiness
      */
    private function declareReady(done : VoidCb):Void {
        player._rs.announce();
        defer(done.void());
    }

/* === Computed Instance Fields === */

    private var appDir(get, never):AppDir;
    private inline function get_appDir() return player.app.appDir;

/* === Instance Fields === */
    
    private var player : Player;
}
