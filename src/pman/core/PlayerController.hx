package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.media.Duration;

import gryffin.media.*;

import Std.*;
import tannus.math.TMath.*;
import gryffin.Tools.defer;

import pman.core.*;
import pman.core.PlayerPlaybackProperties;
import pman.core.PlaybackTarget;
import pman.core.PlayerStatus;
import pman.media.*;
import pman.async.*;

import electron.ext.*;
import electron.ext.GlobalShortcut in Gs;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.core.PlayerTools;
using pman.media.MediaTools;

class PlayerController {
    /* Constructor Function */
    public function new(player : Player):Void {
        this.player = player;
    }

/* === Instance Methods === */

    /**
      * play the current media
      */
    public function play():Void {
        player.sim(_.play());
    }

    /**
      * pause the current media
      */
    public function pause():Void {
        player.sim(_.pause());
    }

    /**
      * toggle media playback
      */
    public function togglePlayback():Void {
        player.sim(_.togglePlayback());
    }

	/**
	  * repeat the current track
	  */
	public function repeatTrack():Void{
		player.currentTime = 0;
	}

    /**
      * get the current Player status
      */
    @:access( pman.media.LocalMediaObjectPlaybackDriver )
    public function getStatus():PlayerStatus {
        var status : PlayerStatus;
        switch ( player.target ) {
            case PTThisDevice:
                if (player.session.hasMedia()) {
                    if (Std.is(player.session.playbackDriver, LocalMediaObjectPlaybackDriver)) {
                        var mo:MediaObject = cast(cast(player.session.playbackDriver, LocalMediaObjectPlaybackDriver<Dynamic>).mediaObject, MediaObject);
                        var me = mo.getUnderlyingMediaObject();
                        var readyState:MediaReadyState = me.readyState;
                        switch ( readyState ) {
                            case HAVE_NOTHING, HAVE_METADATA:
                                status = Waiting;

                            case HAVE_CURRENT_DATA, HAVE_FUTURE_DATA, HAVE_ENOUGH_DATA:
                                if ( ended ) {
                                    status = Ended;
                                }
                                else if ( paused ) {
                                    status = Paused;
                                }
                                else {
                                    status = Playing;
                                }

                            default:
                                status = Empty;
                                throw 'What the fuck';
                        }
                    }
                    else {
                        status = Empty;
                    }
                }
                else {
                    status = Empty;
                }

            case PTChromecast( cc ):
                return cc.getPlayerStatus();

            default:
                status = Empty;
                throw 'What the fuck';
        }
        return status;
    }

    /**
      * handle per-frame logic
      */
    public function tick():Void {
        switch ( player.target ) {
            case PTThisDevice:
                null;

            case PTChromecast( cc ):
                cc.tick();
        }

        if (session.hasMedia()) {
            var pp = session.pp;

            mediaVolume = pp.volume;
            mediaPlaybackRate = pp.speed;
            mediaMuted = pp.muted;

            var currentStatus = getStatus();
            switch ( currentStatus ) {
                case Ended:
                    var ls = lastStatus;
                    trace(repeat + "");
                    switch (repeat) {
                        case RepeatOff:
                            if (session.indexOfCurrentMedia() == (session.playlist.length-1)) return;
                            else{
                                player.gotoNext({
                                    ready: function() {
                                        switch ( ls ) {
                                            case Playing:
                                                player.play();
                                            default:
                                                null;
                                        }
                                    }
                                });
                            }
                        case RepeatIndefinite:
                            repeatTrack();
                            switch ( ls ){
                                case Playing:
                                    player.play();
                                default:
                                    null;
                            }
                        case RepeatOnce:
                            repeat = RepeatOff;
                            repeatTrack();
                            switch ( ls ){
                                case Playing:
                                    player.play();
                                default:
                                    null;
                            }
                        case RepeatPlaylist:
                            player.gotoNext({
                                ready: function() {
                                    switch ( ls ) {
                                        case Playing:
                                            player.play();
                                        default:
                                            null;
                                    }
                                }
                            });
                        default:
                            trace("HOW EVEN?!");
                    }
                default:
                    lastStatus = currentStatus;
            }
        }
    }

/* === Computed Instance Fields === */

    /**
      * the duration of the current media
      */
	public var duration(get, never):Duration;
	private function get_duration() {
	    switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getDuration(), new Duration());

            default:
                return new Duration();
	    }
    }

    /**
      * the duration of the current media
      */
    public var durationTime(get, never):Float;
    private function get_durationTime() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getDurationTime(), 0.0);

            default:
                return 0.0;
        }
    }

    /**
      * whether the current media is paused
      */
    public var paused(get, never):Bool;
    private function get_paused() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getPaused(), false);

            default:
                return false;
        }
    }

    /**
      * the current playback position in the current media
      */
    public var currentTime(get, set):Float;
    private function get_currentTime() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getCurrentTime(), 0.0);

            case PTChromecast(c):
                return c.currentTime;

            default:
                return 0.0;
        }
    }
    private function set_currentTime(newtime) {
        switch ( player.target ) {
            case PTThisDevice:
                player.sim(_.setCurrentTime( newtime ));
                defer(player.dispatch.bind('seek', currentTime));
                return currentTime;

            case PTChromecast(c):
                return (c.currentTime = newtime);

            default:
                return newtime;
        }
    }

    /**
      * the current volume
      */
	public var volume(get, set):Float;
	private inline function get_volume():Float return session.pp.volume;
	private inline function set_volume(v : Float):Float return (session.pp.volume = v);

    /**
      * the current playback speed
      */
	public var playbackRate(get, set):Float;
	private inline function get_playbackRate():Float return session.pp.speed;
	private inline function set_playbackRate(v : Float):Float return (session.pp.speed = v);

    /**
      * whether to shuffle tracks
      */
	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return session.pp.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (session.pp.shuffle = v);

    /**
      * whether media is muted
      */
	public var muted(get, set):Bool;
	private inline function get_muted() return session.pp.muted;
	private inline function set_muted(v) return (session.pp.muted = v);

    public var repeat(get, set):RepeatType;
	private inline function get_repeat() return session.pp.repeat;
	private inline function set_repeat(v) return (session.pp.repeat = v);

    /**
      * whether or not the current media has ended
      */
    public var mediaEnded(get, never):Bool;
    private function get_mediaEnded() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getEnded(), false);

            default:
                return false;
        }
    }

    /**
      * whether or not the current media has ended
      */
    public var ended(get, never):Bool;
    private function get_ended() {
        return mediaEnded;
    }

    /**
      * the media's current volume
      */
    public var mediaVolume(get, set):Float;
    private function get_mediaVolume() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getVolume(), 1.0);

            case PTChromecast(c):
                return c.volume;

            default:
                return 1.0;
        }
    }
    private function set_mediaVolume(v) {
        switch ( player.target ) {
            case PTThisDevice:
                player.sim(_.setVolume(v));
                return mediaVolume;

            case PTChromecast(c):
                return (c.volume = v);

            default:
                return v;
        }
    }

    /**
      * whether the current media is currently muted
      */
    public var mediaMuted(get, set):Bool;
    private function get_mediaMuted() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getMuted(), false);

            case PTChromecast(c):
                return c.muted;

            default:
                return false;
        }
    }
    private function set_mediaMuted(v) {
        switch ( player.target ) {
            case PTThisDevice:
                player.sim(_.setMuted(v));
                return mediaMuted;

            case PTChromecast( c ):
                return (c.muted = v);

            default:
                return v;
        }
    }

    /**
      * the media's current playback rate
      */
    public var mediaPlaybackRate(get, set):Float;
    private function get_mediaPlaybackRate() {
        switch ( player.target ) {
            case PTThisDevice:
                return player.sim(_.getPlaybackRate(), 1.0);

            default:
                return 1.0;
        }
    }
    private function set_mediaPlaybackRate(v) {
        switch ( player.target ) {
            case PTThisDevice:
                player.sim(_.setPlaybackRate( v ));
                return mediaPlaybackRate;

            default:
                return v;
        }
    }

    // the Player's session
    private var session(get, never):PlayerSession;
    private inline function get_session():PlayerSession return player.session;

/* === Instance Fields === */

    public var player : Player;

    private var lastStatus : Null<PlayerStatus> = null;
}
