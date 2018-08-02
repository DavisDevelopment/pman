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

class AppDir {
    public function new():Void {
        #if renderer_process
        playlists = new AppDirPlaylists( this );
        #end
    }

/* === Instance Methods === */

    public function appPath(?sub:String):Path {
        var res:Path = Paths.appPath();
        if (sub != null)
            res = res.plusString( sub ).normalize();
        return res;
    }

    public function path():Path return Paths.userData();
    public function dir():Directory return folder(path());
    public function subpath(sub:String):Path return path().plusString(sub).normalize();
    public function folder(path:Path,?create:Bool):Directory return new Directory(path, create);
    public function file(path:Path):File return new File(path);
    public function sessionsPath():Path return subpath('player_sessions');
    public function sessionsDirectory():Directory return folder(sessionsPath());
    public function playlistsPath():Path return subpath('saved_playlists');
    public function playlistsDirectory():Directory return folder(playlistsPath());
    public function playbackSettingsPath():Path return subpath('playbackProperties.dat');
    public function playbackSettingsFile():File return file(playbackSettingsPath());
    public function playlistPath(name:String):Path {
        if (!name.endsWith('.xspf')) {
            name += '.xspf';
        }
        return playlistsPath().plusString(name).normalize();
    }
    public function playlistFile(name:String):File {
        return file(playlistPath( name ));
    }
    public function playlistFileData(name:String):Maybe<ByteArray> {
        var file = playlistFile( name );
        if ( file.exists ) {
            return file.read();
        }
        else return null;
    }
    public function allSavedPlaylistNames():Array<String> {
		var names = Fs.readDirectory(playlistsPath()).map.fn(Path.fromString(_));
		return names.filter.fn(_.extension == 'xspf').map.fn( _.basename );
    }
    public function playlistExists(name : String):Bool {
        return Fs.exists(playlistPath( name ));
    }
    public function preferencesPath():Path return subpath('preferences.dat');
    public function preferencesFile():File return file(preferencesPath());

    public function lastSessionPath():Path return subpath('session.dat');
    public function getMediaSources(done : Cb<Array<Path>>):Void {
        defer(function() {
            var results = [
                Paths.music(),
                Paths.videos()
            ];
            defer(function() {
                done(null, results);
            });
        });
    }
    public function templatesPath():Path return appPath('assets/templates');
    public function templatePath(name : String):Path return templatesPath().plusString(name).normalize();
    public function readTemplate(name : String):Null<String> {
        var path = templatePath( name );
        if (ttc.exists( path )) {
            return ttc[path];
        }
        else {
            if (Fs.exists( path )) {
                return (ttc[path] = Std.string(Fs.read( path )));
            }
            else {
                return null;
            }
        }
    }
    public function getTemplate(name : String):Null<Template> {
        var path = templatePath( name );
        if (tc.exists( path )) {
            return tc[path];
        }
        else {
            var text = readTemplate( name );
            if (text == null) {
                return null;
            }
            else {
                var template = new Template( text );
                return (tc[path] = template);
            }
        }
    }
    public function snapshotPath():Path return Paths.pictures().plusString('pman_snapshots').normalize();
    public function mediaIdCachePath():Path return subpath('media_cache.json');

/* === Instance Fields === */

    #if renderer_process
    public var playlists : AppDirPlaylists;
    #end

    // template cache
    private var ttc : Null<Dict<Path, String>> = {new Dict();};
    private var tc : Null<Dict<Path, Template>> = {new Dict();};

/* === Static Methods === */

    public static function getAppPath(?sub : String):Path {
        var res = Paths.appPath();
        if (sub != null)
            res = res.plusString(sub).normalize();
        return res;
    }
}
