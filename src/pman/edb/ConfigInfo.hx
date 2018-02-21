package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import electron.ext.*;
import electron.Tools.*;

#if renderer_process

import pman.core.*;
import pman.media.Playlist;
import pman.Globals.*;
import pman.edb.AppDirPlaylists;

#end

import pman.core.JsonData;
import pman.core.PlayerPlaybackProperties;
import pman.async.*;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Template;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

@bind(
    '_lastDirectory'
)
class ConfigInfo extends JsonFileStorage {
    public function new():Void {
        super(new AppDir().subpath('cfgi.dat'));

        if (lastDirectory == null) {
            lastDirectory = Paths.videos();
        }

        if (visualizer == null) {
            visualizer = Bars;
        }

        if (restorePreviousSession == null) {
            restorePreviousSession = true;
        }

        if (sessionToRestore == null) {
            sessionToRestore = 'session.dat';
        }

        if (autoSaveSession == null) {
            autoSaveSession = true;
        }
    }

/* === Instance Methods === */

/* === Computed Instance Fields === */

    // the last directory that was interacted with
    public var lastDirectory(get,set):Null<Path>;
    private inline function get_lastDirectory() return _lastDirectory!=null?new Path(_lastDirectory):null;
    private inline function set_lastDirectory(v) return Path.fromString(_lastDirectory = (v != null ? Std.string(v) : null));

/* === Instance Fields === */

    public var visualizer:Null<VisualizerName>;
    public var restorePreviousSession: Null<Bool>;
    public var autoSaveSession: Null<Bool>;
    public var sessionToRestore: Null<String>;

    private var _lastDirectory:String;
}

@:enum
abstract VisualizerName (String) from String to String {
    var Bars = 'bars';
    var Spectograph = 'spectograph';
}
