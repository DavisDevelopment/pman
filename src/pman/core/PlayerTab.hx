package pman.core;

import haxe.extern.EitherType;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.math.Random;
import tannus.async.*;
import tannus.async.promises.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.core.JsonData;

import haxe.Serializer;
import haxe.Unserializer;

import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using Std;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.RandomTools;

/**
  * class to represent a Tab in the player window
  */
class PlayerTab {
    /* Constructor Function */
    public function new(sess : PlayerSession):Void {
        session = sess;

        type = Player;
        playlist = new Playlist();
        focusedTrack = null;
        blurredTrack = null;
    }

/* === Instance Methods === */

	/**
	  * check whether there is any media attached to [this] Tab
	  */
	public inline function hasMedia():Bool {
	    return track.exists;
	}

	/**
	  * check whether [this] Tab has focus
	  */
	public inline function hasFocus():Bool {
	    return (session.activeTab == this);
	}

	/**
	  * get the index of the current media
	  */
	public inline function indexOfCurrentMedia():Int {
	    return track.ternary(playlist.indexOf(_), -1);
	}

	/**
	  * open [this] Tab
	  */
	public function open():Void {
	    if (!session.tabs.has( this )) {
	        session.tabs.push( this );
	    }
	    focus();
	}

    /**
      * shift focus to [this] Tab
      */
	public inline function focus():Void {
	    session.setTab(session.tabs.indexOf( this ));
	}

	/**
	  * close [this] Tab
	  */
	public inline function close():Void {
	    session.deleteTab(session.tabs.indexOf( this ));
	}

/* === Playlist Methods === */

    public inline function getTrack(index : Int):Maybe<Track> {
        return playlist[index];
    }

    public inline function getTrackIndex(track : Track):Int {
        return playlist.indexOf( track );
    }

    public inline function hasTrack(track : Track):Bool {
        return playlist.has( track );
    }

    /**
      * remove the given Track
      */
    public function removeTrack(track : Track):Bool {
        var ret = playlist.remove( track );
        if (playlist.length == 0) {
            close();
        }
        return ret;
    }

    public inline function insertTrack(pos:Int, track:Track, ?report:Bool):Void {
        playlist.insert(pos, track, report);
    }

/* === Serialization Methods === */

	/**
	  * serialize [this] tab
	  */
	public function hxSerialize(s : Serializer):Void {
	    inline function w(x:Dynamic) s.serialize( x );

	    w( type );
	    switch ( type ) {
            case Player:
                w(playlist.toStrings());
                w(indexOfCurrentMedia());

            default:
                w( null );
	    }
	}

    /**
      * unserialize [this] tab
      */
	public function hxUnserialize(u : Unserializer):Void {
	    inline function v():Dynamic return u.unserialize();

	    type = v();
	    switch ( type ) {
            case Player:
                var tl = Playlist.fromStrings(v());
                this.playlist = new Playlist();
                for (track in tl) {
                    var path = track.getFsPath();
                    if (path != null) {
                        if (Fs.exists( path )) {
                            playlist.push( track );
                        }
                        else {
                            //_attemptToLocateMissingFile( path );
                            //TODO
                        }
                    }
                    else {
                        playlist.push( track );
                    }
                }
                blurredTrack = playlist[v()];

            default:
                v();
	    }
	}

    /**
      * attempt to find a missing file
      */
	private function _attemptToLocateMissingFile(track:Track, path:Path, done:VoidCb):Void {
	    var folder:Path = path.directory;
	    while (folder.pieces.length > 1 && !Fs.exists( folder )) {
	        folder = folder.directory;
	    }
	    if (Fs.exists( folder )) {
	        var names = Fs.readDirectory( folder );
	        var paths = names.map(name->folder.plusString( name ));
	        var test = electron.ext.FileFilter.ALL.test.bind();
	        paths = paths.filter(path->test(path.toString()));
	        if (!paths.empty()) {
	            track.getData(function(?error, ?data:TrackData) {
	                if (error != null) {
	                    done( error );
                    }
                    else if (data != null) {
                        //TODO
                    }
                    else {
                        done();
                    }
	            });
	        }
            else {
                done();
            }
	    }
        else {
            done();
        }
	}

/* === Computed Instance Fields === */

    // the Player instance
    public var player(get, never):Player;
    private inline function get_player() return session.player;

    public var track(get, never):Maybe<Track>;
    private inline function get_track():Maybe<Track> {
        return new Maybe(focusedTrack || blurredTrack);
    }

    public var title(get, never):Maybe<String>;
    private inline function get_title() {
        return track.ternary(_.title, null);
    }

/* === Instance Fields === */

    public var session : PlayerSession;
    public var type : TabType;
    public var playlist : Playlist;

    public var focusedTrack : Maybe<Track>;
    public var blurredTrack : Maybe<Track>;
}

/*
  enum representing different types of tabs
  NOTE: will most likely need to be a full-featured enum
 */
@:enum
abstract TabType (Int) from Int {
    var Player = 0;
    var Browser = 1;
}
