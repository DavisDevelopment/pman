package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

import pman.core.*;
import pman.media.*;
import pman.async.*;
import pman.async.tasks.*;
import pman.bg.db.*;
import pman.edb.*;

import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;
using pman.async.Asyncs;
using pman.bg.URITools;

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
        var src:String = (player.flag('src') : String);
        var cli:Bool = (launchInfo.argv.hasContent() || src == 'cli' || src == 'command-line-input');

        if ( cli ) {
            cfg.restorePreviousSession = false;
            cfg.autoSaveSession = false;
            cfg.push();

            //
            startup_load_cli( done );
        }
        else {
            //
            startup_load_session( done );
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
        // load the default session
        if ( cfg.restorePreviousSession ) {
            player.session.restore(function(?error) {
                done.forward( error );
                declareReady( done );
            });
        }
        else {
            declareReady( done );
        }
    }

    /**
      * prompt the user whether to restore session
      */
    private function startup_confirm_load_session(done : VoidCb):Void {
        if (cfg.restorePreviousSession && player.session.hasSavedState()) {
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
        // parse the launch info
        parseLaunchInfo();

        // expand path-list
        if (paths.hasContent()) {
            paths = expand_paths( paths );
        }

        // resolve paths to tracks
        if (paths.hasContent()) {
            // resolve the tracks
            var tracks:Array<Track> = resolve_tracks( paths );

            // declare readiness once this task is done
            declareReady(function(?err) {
                done.forward( err );

                // add the resolved tracks to the player
                defer(function() {
                    player.addItemList(tracks, function() {
                        done();
                    });

                    cfg.restorePreviousSession = true;
                    cfg.autoSaveSession = true;
                    cfg.push();
                });
            });
        }
        else {
            declareReady( done );
        }
    }

    /**
      * convert list of arbitrary paths to a list of paths that all point to openable media files that actually exist
      */
    private inline function expand_paths(a : Array<Path>):Array<Path> {
        return new PathListConverter().convert(a.filter.fn(Fs.exists(_)));
    }

    /**
      * convert list of Paths into a list of Tracks
      */
    private function resolve_tracks(a : Array<Path>):Array<Track> {
        return new FileListConverter().convert(a.map.fn(new File( _ ))).toArray();
    }

    /**
      * parse out the launchInfo
      */
    private function parseLaunchInfo(?i: LaunchInfo):Void {
        if (i == null) {
            i = launchInfo;
        }

        //TODO parse launch info more exhaustively using an ArgParser object
        paths = absolutes(i.argv, i.cwd, i.env);
    }

    /**
      * resolve a list of Strings to a list of absolute paths
      */
    private function absolutes(array:Array<String>, ?cwd:Path, ?env:Map<String, String>):Array<Path> {
        if (array.empty()) {
            return [];
        }
        else {
            if (cwd == null) {
                cwd = Sys.getCwd();
            }
            if (env == null) {
                env = Sys.environment();
            }

            var results:Array<Path> = new Array();
            for (s in array) {
                var path:Null<Path> = absolute(s, cwd, env);
                if (path != null) {
                    results.push( path );
                }
            }
            return results;
        }
    }

    /**
      * resolve the given String to an absolute Path
      */
    private function absolute(s:String, ?cwd:Path, ?env:Map<String, String>):Null<Path> {
        if (cwd == null) {
            cwd = Sys.getCwd();
        }

        if (env == null) {
            env = Sys.environment();
        }

        var system = Sys.systemName();
        if (s.hasContent()) {
            var path:Path = Path.fromString( s );
            if ( path.absolute ) {
                return path;
            }
            else {
                inline function isReal(x: Path):Bool return Fs.exists( x );

                var resolvedPath:Path = cwd.plusString( s );
                if (isReal( resolvedPath )) {
                    return resolvedPath;
                }
                else {
                    if (env.exists('PATH')) {
                        var envPaths:Array<Path> = (env['PATH'] : String).split(system == 'Windows' ? ';' : ':').map(s -> Path.fromString( s ));
                        for (ep in envPaths) {
                            resolvedPath = ep.plusString( s );
                            if (isReal( resolvedPath )) {
                                return resolvedPath;
                            }
                        }
                    }
                }

                return path;
            }
        }
        else {
            return null;
        }
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

    private var cfg(get, never):ConfigInfo;
    private inline function get_cfg() return database.configInfo;

    private var launchInfo(get, never):LaunchInfo;
    private inline function get_launchInfo() return bpmain.launchInfo;

/* === Instance Fields === */
    
    private var player : Player;
    private var paths : Array<Path>;
}
