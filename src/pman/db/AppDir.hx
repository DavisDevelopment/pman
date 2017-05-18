package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import electron.ext.*;
import electron.Tools.*;

#if renderer_process

import pman.core.*;

#end

import pman.core.JsonData;
import pman.async.*;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class AppDir {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/**
	  * get the Path to [this]
	  */
	public inline function path():Path {
		return App.getPath( UserData );
	}

	/**
	  * get the directory object itself
	  */
	public inline function dir():Directory {
		return new Directory(path());
	}

    /**
      * get the Path to the player_sessions directory
      */
	public inline function sessionsPath():Path return path().plusString( 'player_sessions' );

	/**
	  * get the player_session directory, creating it if necessary
	  */
	public inline function sessionsDirectory():Directory {
	    return new Directory(sessionsPath(), true);
	}

	/**
	  * get the Path to the saved_playlists directory
	  */
	public function playlistsPath():Path {
		return (path().plusString( 'saved_playlists' ));
	}

	/**
	  * get the saved_playlists directory, creating it if necessary
	  */
	public inline function playlistsDirectory():Directory {
	    return new Directory(playlistsPath(), true);
	}

	/**
	  * get the Path to the playback settings file
	  */
	public inline function playbackSettingsPath():Path return path().plusString('playbackProperties.dat');

	/**
	  * get the playback settings file
	  */
	public inline function playbackSettingsFile():File return new File(playbackSettingsPath());

    /**
      * get a file from the saved_playlists by name
      */
	public inline function playlistFile(name : String):File {
	    return playlistsDirectory().file(name + '.xspf');
	}

	/**
	  * get the names of all saved playlists
	  */
	public function allSavedPlaylistNames():Array<String> {
		var names = Fs.readDirectory(playlistsPath()).map.fn(Path.fromString(_));
		return names.filter.fn(_.extension == 'xspf').map.fn(_.basename);
	}

	/**
	  * check if there is a saved playlist by the given name
	  */
	public inline function playlistExists(name : String):Bool {
	    return Fs.exists(playlistsPath().plusString(name + '.xspf').toString());
	}

	/**
	  * get the Path to the preferences file
	  */
	public inline function preferencesPath():Path {
	    return path().plusString( 'preferences.dat' );
	}

	/**
	  * get the preferences File
	  */
	public inline function preferencesFile():File {
	    return new File(preferencesPath());
	}

	/**
	  * save the given session info with the given name
	  */
	public function saveSession(name:String, session:JsonSession):Void {
	    var sd = sessionsDirectory();
	    var sf = sd.file('$name.session');
	    var data = encodeSession( session );
	    sf.write(ByteArray.ofString( data ));
	}

    /**
      * load a saved session by name
      */
	public function loadSession(name : String):JsonSession {
	    var sf = sessionsDirectory().file('$name.session');
	    var data:JsonSession = decodeSession(sf.read().toString());
	    return data;
	}

    /**
      * check for existence of named session
      */
	public function hasSavedSession(name : String):Bool {
	    return Fs.exists(sessionsPath().plusString( '$name.session' ).toString());
	}

	/**
	  * get list of the names of all saved sessions
	  */
	public function allSavedSessionNames():Array<String> {
	    var sd = sessionsDirectory();
	    return sd.subpaths.filter.fn(_.extension == 'session').map.fn(_.name.beforeLast('.'));
	}

    /**
      * serialize the given Session info into a String
      */
	private function encodeSession(s : JsonSession):String {
	    var serializer = new Serializer();
	    serializer.useCache = true;
	    inline function w(x : Dynamic){
	        serializer.serialize( x );
	    }

	    w( s.playbackProperties.speed );
	    w( s.playbackProperties.volume );
	    w( s.playbackProperties.shuffle );
	    w( s.playlist.length );
	    for (i in 0...s.playlist.length) {
	        w(s.playlist[i]);
	    }
	    w( s.nowPlaying.track );
	    w( s.nowPlaying.time );
	    return serializer.toString();
	}

    /**
      * unserialize the given String as Session info
      */
	private function decodeSession(s : String):JsonSession {
	    var us = new Unserializer( s );
	    inline function val<T>():T {
	        return us.unserialize();
	    }

        var pbProps:JsonPlaybackProperties = {
            speed: val(),
            volume: val(),
            shuffle: val()
        };
        var playlist:Array<String> = new Array();
        var len:Int = val();
        for (i in 0...len) {
            playlist.push(val());
        }
        var nowPlaying:JsonPlayerState = {
            track: val(),
            time: val()
        };
        return {
            playbackProperties: pbProps,
            playlist: playlist,
            nowPlaying: nowPlaying
        };
	}

    /**
      * get path to the 'session.dat' file
      */
	public inline function lastSessionPath():Path {
	    return path().plusString( 'session.dat' );
	}

	/**
	  * get full list of media-source directories
	  */
	public function getMediaSources(done : Array<Path> -> Void):Void {
	    defer(function() {
	        var results = [];
	        
	        results.push(App.getPath(Videos));

            done( results );
	    });
	}

    /**
      * get path to a template file
      */
	public inline function templatePath(name : String):Path {
	    return appPath('assets/templates/$name');
	}

	/**
	  * read contents of a template file
	  */
	public function readTemplate(name : String):Null<String> {
	    var tp = templatePath( name );
	    if (Fs.exists( tp )) {
	        return (Fs.read( tp ).toString());
	    }
        else return null;
	}

	/**
	  * get a Template
	  */
	public function getTemplate(name : String):Null<haxe.Template> {
	    var tt = readTemplate( name );
	    if (tt == null)
	        return null;
	    return new haxe.Template( tt );
	}

    /**
      * get the path of the application
      */
	public function appPath(?s : String):Path {
	    var p:Path = App.getAppPath();
	    if (s != null)
	        p = p.plusString( s );
	    return p;
	}

#if renderer_process

    /**
      * check for existence of file containing saved playback properties
      */
    public inline function hasSavedPlaybackSettings():Bool {
        return Fs.exists(playbackSettingsPath().toString());
    }

    /**
      * write encoded playback-properties to file
      */
    public inline function savePlaybackSettings(p : Player):Void {
        playbackSettingsFile().write(ByteArray.ofString(encodePlaybackSettings( p )));
    }

    /**
      * read, decode, and restore saved playback properties
      */
    public function loadPlaybackSettings(p:Player, ?cb:VoidCb):Void {
        function done(?error : Dynamic) {
            if (cb != null) {
                defer(function() cb(error));
            }
        }
        //decodePlaybackSettings(playbackSettingsFile().read().toString(), p, done);
        try {
            var encoded = Std.string(playbackSettingsFile().read());
            decodePlaybackSettings(encoded, p, done);
        }
        catch (error : Dynamic) {
            done( error );
        }
    }

    /**
      * serialize playback properties
      */
    private function encodePlaybackSettings(p : Player):String {
        var s = new Serializer();
        inline function w(x:Dynamic){
            s.serialize( x );
        }

        w( p.playbackRate );
        w( p.volume );
        w( p.shuffle );
        w( p.muted );

        return s.toString();
    }

    /**
      * decode and restore playback properties
      */
    private function decodePlaybackSettings(s:String, p:Player, ?done:VoidCb):Void {
        inline function cb(?error) {
            if (done != null) {
                defer(function() done(error));
            }
        }
        try {
            var u = new Unserializer( s );
            inline function val<T>():T return u.unserialize();

            p.playbackRate = val();
            p.volume = val();
            p.shuffle = val();
            p.muted = val();

            cb();
        }
        catch (error : Dynamic) {
            cb( error );
        }
    }

#end

/* === Instance Fields === */

}
