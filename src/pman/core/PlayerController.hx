package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.media.Duration;

import gryffin.media.*;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

import pman.core.*;
import pman.core.PlayerPlaybackProperties;
import pman.core.PlaybackTarget;
import pman.core.PlayerStatus;
import pman.bg.media.MediaFeature;
import pman.media.*;
import pman.async.*;

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
        //player.sim(_.play());
        player.asf([Playback], _.play());
    }

    /**
     * pause the current media
     */
    public function pause():Void {
        player.asf([Playback], _.pause());
    }

    /**
     * toggle media playback
     */
    public function togglePlayback():Void {
        //player.sim(_.togglePlayback());
        player.asf([Playback], _.togglePlayback());
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
    @:access( pman.media.LocalMediaObjectMediaDriver )
        public function getStatus():PlayerStatus {
            // declare variable to hold the current status
            var status : PlayerStatus;

            // based on current playback target
            switch ( player.target ) {
                // if playing on local device
                case PTThisDevice:
                    // if there is any media mounted
                    if (player.session.hasMedia()) {
                        // if the driver for that media is using a MediaObject
                        if (Std.is(player.session.mediaDriver, LocalMediaObjectMediaDriver)) {
                            // get that media object
                            var mo:MediaObject = cast(cast(player.session.mediaDriver, LocalMediaObjectMediaDriver<Dynamic>).mediaObject, MediaObject);
                            // and then the one on which it is built
                            var me = mo.getUnderlyingMediaObject();
                            // check its [readyState] property
                            var readyState:MediaReadyState = me.readyState;
                            switch ( readyState ) {
                                // there is nothing loaded, or only metadata is loaded
                                case HAVE_NOTHING, HAVE_METADATA:
                                    // we are waiting
                                    status = Waiting;

                                    // we have data that can be played
                                case HAVE_CURRENT_DATA, HAVE_FUTURE_DATA, HAVE_ENOUGH_DATA:
                                    // if media-object has ended
                                    if ( ended ) {
                                        // then that is our status: ended
                                        status = Ended;
                                    }
                                    // otherwise, if MediaObject is paused
                                    else if ( paused ) {
                                        // our status is paused
                                        status = Paused;
                                    }
                                    // otherwise
                                    else {
                                        // we must be playing
                                        status = Playing;
                                    }

                                    // status defaults to empty
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

                    // if playback target is a chromecast
                case PTChromecast( cc ):
                    // ask the cast-controller for our status
                    return cc.getPlayerStatus();

                    // default to empty
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
        // do some stuff based on playback-target
        switch ( player.target ) {
            case PTThisDevice:
                null;

                // 'tick' the chromecast-controller if we have one
            case PTChromecast( cc ):
                cc.tick();
        }

        // if media is mounted
        if (session.hasMedia()) {
            // get shorthand for playback-properties
            var pp = session.pp;

            // copy over playback-properties
            mediaVolume = pp.volume;
            mediaPlaybackRate = pp.speed;
            mediaMuted = pp.muted;

            // get currentStatus
            if (isEnded()) {
                // check the 'repeat' setting
                switch ( repeat ) {
                    // if it's disabled
                    case RepeatOff:
                        // if we're at the last item in the queue
                        if (session.indexOfCurrentMedia() == (session.playlist.length - 1)) {
                            // do nothing
                            return ;
                        }
                        // otherwise
                        else {
                            // move forward in the queue
                            player.gotoNext({
                                // when the next track is ready
                                ready: function() {
                                    // if autoplay is enabled
                                    if ( preferences.autoPlay ) {
                                        // start playing
                                        player.play();
                                    }
                                }
                            });
                        }

                        // if it's set to repeat indefinitely
                    case RepeatIndefinite:
                        // repeat the track
                        repeatTrack();

                        // if autoplay is enabled
                        if ( preferences.autoPlay ) {
                            // start playing
                            player.play();
                        }

                        // if it's set to repeat once
                    case RepeatOnce:
                        // then now disable it
                        repeat = RepeatOff;

                        // repeat the track
                        repeatTrack();

                        // if autoplay is enabled
                        if ( preferences.autoPlay ) {
                            // then start playing
                            player.play();
                        }

                        // if it's set to repeat the entire playlist
                    case RepeatPlaylist:
                        // move forward in the queue
                        player.gotoNext({
                            ready: function() {
                                if ( preferences.autoPlay ) {
                                    player.play();
                                }
                            }
                        });

                        // if some terrifying unexpected outcome has occurred
                    default:
                        report('What the fuck?');
                }
            }
        }
    }

    /**
     * attempt to determine whether the current media has 'ended'
     */
    public function isEnded():Bool {
        if (session.hasMedia() && player.track != null) {
            inline function fe(x: MediaFeature) return player.track.hasFeature( x );
            if (fe( CurrentTime ) && fe( Duration )) {
                if (player.currentTime >= player.durationTime) {
                    return true;
                }
                else if (player.track.data != null) {
                    var endTime = player.track.data.getEndTime();
                    if (endTime != null && player.currentTime >= endTime) {
                        return true;
                    }
                } 
            }
        }

        return false;
    }

/* === Computed Instance Fields === */

    /**
     * the duration of the current media
     */
    public var duration(get, never):Duration;
    private function get_duration() {
        switch ( player.target ) {
            case PTThisDevice:
                //return player.sim(_.getDuration(), new Duration());
                return player.asf([Duration], _.getDuration(), new Duration());

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
                //return player.sim(_.getDurationTime(), 0.0);
                return player.asf([Duration], _.getDurationTime(), 0.0);

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
                //return player.sim(_.getPaused(), false);
                return player.asf([Playback], _.getPaused(), false);

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
                //return player.sim(_.getCurrentTime(), 0.0);
                return player.asf([CurrentTime], _.getCurrentTime(), 0.0);

            case PTChromecast(c):
                return c.currentTime;

            default:
                return 0.0;
        }
    }
    private function set_currentTime(newtime) {
        switch ( player.target ) {
            case PTThisDevice:
                //player.sim(_.setCurrentTime( newtime ));
                player.asf([CurrentTime], _.setCurrentTime( newtime ));
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

    public var scale(get, set):Float;
    private inline function get_scale() return session.pp.scale;
    private inline function set_scale(v) return (session.pp.scale = v);

    /**
     * whether or not the current media has ended
     */
    public var mediaEnded(get, never):Bool;
    private function get_mediaEnded() {
        switch ( player.target ) {
            case PTThisDevice:
                //return player.sim(_.getEnded(), false);
                return player.asf([End], _.getEnded(), false);

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
                //return player.sim(_.getVolume(), 1.0);
                return player.asf([Volume], _.getVolume(), 1.0);

            case PTChromecast(c):
                return c.volume;

            default:
                return 1.0;
        }
    }
    private function set_mediaVolume(v) {
        switch ( player.target ) {
            case PTThisDevice:
                //player.sim(_.setVolume(v));
                player.asf([Volume], _.setVolume( v ));
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
                return player.asf([Mute], _.getMuted(), {
                    player.asf([Volume], (mediaVolume == 0.0), false);
                });

            case PTChromecast(c):
                return c.muted;

            default:
                return false;
        }
    }
    private function set_mediaMuted(v) {
        switch ( player.target ) {
            case PTThisDevice:
                player.asf([Mute], _.setMuted(v), {
                    mediaVolume = (v ? 0.0 : 0.10);
                });
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
                //return player.sim(_.getPlaybackRate(), 1.0);
                return player.asf([PlaybackSpeed], _.getPlaybackRate(), 1.0);

            default:
                return 1.0;
        }
    }
    private function set_mediaPlaybackRate(v) {
        switch ( player.target ) {
            case PTThisDevice:
                //player.sim(_.setPlaybackRate( v ));
                player.asf([PlaybackSpeed], _.setPlaybackRate( v ));
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
