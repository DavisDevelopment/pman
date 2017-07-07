package pman.core;

import haxe.extern.EitherType;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.math.Random;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.FileFilter;

import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.core.history.PlayerHistoryItem;
import pman.core.history.PlayerHistoryItem as PHItem;
import pman.core.PlayerPlaybackProperties;
import pman.core.JsonData;

import foundation.Tools.*;
import electron.Tools.*;

import haxe.Serializer;
import haxe.Unserializer;

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
	    return (focusedTrack != null);
	}

	/**
	  * check whether [this] Tab has focus
	  */
	public inline function hasFocus():Bool {
	    return (session.activeTab == this);
	}

	/**
	  * serialize [this] tab
	  */
	public function hxSerialize(s : Serializer):Void {
	    inline function w(x:Dynamic) s.serialize( x );

	    w( type );
	    switch ( type ) {
            case Player:
                w(playlist.toStrings());
                w(new Maybe(focusedTrack.or( blurredTrack )).ternary(playlist.indexOf( _ ), -1));

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
                playlist = Playlist.fromStrings(v());
                blurredTrack = playlist[v()];

            default:
                v();
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
