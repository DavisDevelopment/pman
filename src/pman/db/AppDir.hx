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

	public inline function sessionsPath():Path return path().plusString( 'player_sessions' );
	public inline function sessionsDirectory():Directory {
	    return new Directory(sessionsPath(), true);
	}
	public inline function playbackSettingsPath():Path return path().plusString('playbackProperties.dat');
	public inline function playbackSettingsFile():File return new File(playbackSettingsPath());

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
	  * get full list of media-source directories
	  */
	public function getMediaSources(done : Array<Path> -> Void):Void {
	    defer(function() {
	        var results = [];
	        
	        results.push(App.getPath(Videos));

            done( results );
	    });
	}

#if renderer_process

    public inline function hasSavedPlaybackSettings():Bool {
        return Fs.exists(playbackSettingsPath().toString());
    }

    public inline function savePlaybackSettings(p : Player):Void {
        playbackSettingsFile().write(ByteArray.ofString(encodePlaybackSettings( p )));
    }

    public inline function loadPlaybackSettings(p:Player, ?done:Void->Void):Void {
        decodePlaybackSettings(playbackSettingsFile().read().toString(), p, done);
    }

    private function encodePlaybackSettings(p : Player):String {
        var s = new Serializer();
        inline function w(x:Dynamic){
            s.serialize( x );
        }

        w( p.playbackRate );
        w( p.volume );
        w( p.shuffle );

        return s.toString();
    }

    private function decodePlaybackSettings(s:String, p:Player, ?done:Void->Void):Void {
        var u = new Unserializer( s );
        inline function val<T>():T return u.unserialize();

        p.playbackRate = val();
        p.volume = val();
        p.shuffle = val();

        if (done != null) {
            defer( done );
        }
    }

#end

/* === Instance Fields === */

}
