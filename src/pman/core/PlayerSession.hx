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
import pman.core.JsonData;

import foundation.Tools.*;

using Std;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.RandomTools;

/**
  * Object used to represent the current media Playback context
  */
@:allow( pman.core.Player )
class PlayerSession {
	/* Constructor Function */
	public function new(p : Player):Void {
		player = p;

		//mediaContext = new PlayerMediaContext( this );
		playbackProperties = new PlayerPlaybackProperties(1.0, 1.0, false);

		trackChanging = new Signal();
		trackChanged = new Signal();
		focusedTrack = null;
		playlist = new Playlist();
		history = new PlayerHistory( this );

        _listen();
	}

/* === Instance Methods === */

	/**
	  * get the index of the currently playing media
	  */
	public function indexOfCurrentMedia():Int {
		if (hasMedia()) {
			return playlist.indexOf( focusedTrack );
		}
		else {
			return -1;
		}
	}

	/**
	  * add a Media item onto the queue
	  */
	public function addItem(track:Track, ?done:Void->Void, autoLoad:Bool=true):Void {
		if (autoLoad && playlist.empty()) {
			plpush( track );
			load(track, {
				attached: function() {
					if (done != null) {
						done();
					}
				}
			});
		}
		else {
			plpush( track );
			if (done != null) {
				defer( done );
			}
		}
	}

	/**
	  * add a Media item onto the queue
	  */
	private function plpush(track : Track):Void {
		if ( shuffle ) {
			//playlist.insert([0, playlist.length].randint(), track);
			playlist.shuffledPush( track );
		}
		else {
			playlist.push( track );
		}
	}

	/**
	  * mount the given Track, and switch focus to it
	  */
	public function focus(track:Track, ?done:Void->Void):Void {
		var prev = focusedTrack;
		var pre_delta:Delta<Null<Track>> = new Delta(track, prev);
		trackChanging.call( pre_delta );
		if (focusedTrack != null) {
			blur( focusedTrack );
		}
		_mountIfNecessary(track, function() {
			focusedTrack = track;
			player.view.attachRenderer( track.renderer );
			var post_delta:Delta<Null<Track>> = new Delta(focusedTrack, prev);
			trackChanged.call( post_delta );
			if (done != null) {
				done();
			}
		});
	}

	/**
	  * dismount the given Track, and shift focus off of it
	  */
	public function blur(?track : Track):Void {
		// if [track] is not explicitly provided
		if (track == null) {
			// default to [focusedTrack]
			if (hasMedia()) {
				track = focusedTrack;
			}
			// if [focusedTrack] is null
			else {
				// then I guess we're done?
				return ;
			}
		}

		// if [track] is already unmounted, then it cannot be focused, and thus cannot be blurred
		if (!track.isMounted()) {
			throw 'Error: Track is not mounted, and thus cannot be blurred';
		}

		var pre_delta = new Delta(null, track);
		trackChanging.call( pre_delta );

		// dismount the Track
		track.dismount();

		// unlink the Track
		if (track == focusedTrack) {
			player.view.detachRenderer();
			focusedTrack = null;

			var post_delta = new Delta(null, track);
			trackChanged.call( post_delta );
		}
	}

	/**
	  * either mounts [track], and invokes [done] when that has completed,
	  * or simply invokes [done] as soon as the current callStack has finished,
	  * if [track] is already mounted
	  */
	private function _mountIfNecessary(track:Track, done:Void->Void):Void {
		if (track.isMounted()) {
			defer( done );
		}
		else {
			track.mount(function(error : Null<Dynamic>):Void {
				if (error != null) {
					(untyped __js__('console.error'))( error );
					throw error;
				}
				else {
					done();
				}
			});
		}
	}

    /**
      * load the given Track
      */
	public function load(t:Track, ?cb:LoadCallbackOptions):Void {
	    // ensure that [cb] is not null
	    cb = fill_lcbo( cb );

		// push history state
		if (cb.trigger != History) {
		    history.push(Media(LoadTrack( t )));
		}

		// shift focus to [t]
		focus(t, function() {
			if (cb.attached != null) {
				defer( cb.attached );
			}
			var d = focusedTrack.driver;
			if (cb.manipulate != null) {
				// loaded metadata event
				var lmd = d.getLoadedMetadataSignal();
				lmd.once(defer.bind(cb.manipulate.bind( d )));
				lmd.once(function() {
					defer(function() {
						cb.manipulate( d );
					});
				});
			}
			// wait for the media to be ready to play
			if (cb.ready != null) {
				// can play event
				var cp = d.getCanPlaySignal();
				cp.once(function() {
					defer( cb.ready );
				});
			}
		});
	}

	/**
	  * reassign the playlist field
	  */
	public function setPlaylist(pl : Playlist):Void {
	    playlist = pl;
	    var plv = player.page.playlistView;
	    if (plv != null && plv.isOpen) {
	        plv.refresh();
	    }
	}

	/**
	  * check whether [this] Session has any media
	  */
	public inline function hasMedia():Bool {
		//return mc.allValuesPresent();
		return (focusedTrack != null);
	}

	/**
	  * export state to Json
	  */
	public function toJson():JsonSession {
		return {
			playlist: playlist.toJSON(),
			playbackProperties: __playbackPropertiesToJson(),
			nowPlaying: __getJsonPlayerState()
		};
	}

	/**
	  * pull the given JsonSession's data onto [this]
	  */
	public function pullJson(state:JsonSession, callback:Void->Void):Void {
		player.clearPlaylist();
		var stack = new AsyncStack();
		stack.push(function(next) {
			defer(function() {
				//__pullJsonPlaylist( state.playlist );
				var tmp = Playlist.fromJSON( state.playlist );
				var tmpShuffle = player.shuffle;
				player.shuffle = false;
				player.addItemList(tmp.toArray(), function() {
                    player.shuffle = tmpShuffle;
                    next();
				});
			});
		});
		stack.push(function(next) {
			defer(function() {
				__pullJsonPlaybackProperties( state.playbackProperties );
				next();
			});
		});
		stack.push(function(next) {
			defer(function() {
				if (state.nowPlaying != null) {
					__pullJsonPlayerState( state.nowPlaying );
				}
				next();
			});
		});
		stack.run(function() {
			callback();
		});
	}

	/**
	  * pull the given JsonPlaybackProperties onto [this]
	  */
	private function __pullJsonPlaybackProperties(props : JsonPlaybackProperties):Void {
		player.shuffle = props.shuffle;
		player.playbackRate = props.speed;
		player.volume = props.volume;
	}

	/**
	  * pull the given JsonPlayerState
	  */
	private function __pullJsonPlayerState(state : JsonPlayerState):Void {
		// get the Track in question
		var track:Null<Track> = player.getTrack( state.track );
		// open that track
		player.openTrack(track, {
			// when the track is ready to manipulate
			manipulate: function(mc : MediaController) {
				mc.setCurrentTime( state.time );
			}
		});
	}

	/**
	  * convert [playbackProperties] to JsonPlaybackProperties
	  */
	private inline function __playbackPropertiesToJson():JsonPlaybackProperties {
		return {
			speed: pp.speed,
			volume: pp.volume,
			shuffle: pp.shuffle
		};
	}

	/**
	  * get the JsonPlayerState
	  */
	private function __getJsonPlayerState():Null<JsonPlayerState> {
		if (hasMedia()) {
			return {
				track: indexOfCurrentMedia(),
				time: player.currentTime
			};
		}
		else {
			return null;
		}
	}

	/**
	  * fill in a LoadCallbackOptions object
	  */
	private function fill_lcbo(cb : Null<LoadCallbackOptions>):LoadCallbackOptions {
	    if (cb == null) cb = {};
	    if (cb.trigger == null) {
	        cb.trigger = User;
	    }
	    return cb;
	}

	/**
	  * listen for events
	  */
	private function _listen():Void {
	    playbackProperties.changed.on(function() {
	        player.app.appDir.savePlaybackSettings( player );
	    });
	}

/* === Computed Instance Fields === */

	// shorthand name for [mediaContext]
	//public var mc(get, never):PlayerMediaContext;
	//private inline function get_mc():PlayerMediaContext return mediaContext;

	public var pp(get, never):PlayerPlaybackProperties;
	private inline function get_pp():PlayerPlaybackProperties return playbackProperties;

	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return pp.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (pp.shuffle = v);

	public var muted(get, set):Bool;
	private inline function get_muted():Bool return pp.muted;
	private inline function set_muted(v : Bool):Bool return (pp.muted = v);

	public var mediaProvider(get, never):Null<MediaProvider>;
	private inline function get_mediaProvider():Null<MediaProvider> return mft.ternary(_.provider, null);

	public var media(get, never):Null<Media>;
	private inline function get_media():Null<Media> return mft.ternary(_.media, null);

	public var playbackDriver(get, never):Null<PlaybackDriver>;
	private inline function get_playbackDriver():Null<PlaybackDriver> return mft.ternary(_.driver, null);

	public var mediaRenderer(get, never):Null<MediaRenderer>;
	private inline function get_mediaRenderer():Null<MediaRenderer> return mft.ternary(_.renderer, null);

	private var mft(get, never):Maybe<Track>;
	private inline function get_mft():Maybe<Track> return focusedTrack;

	// the currently 'active' Track
	public var focusedTrack(default, set): Null<Track>;
	private inline function set_focusedTrack(v : Null<Track>):Null<Track> {
		return (focusedTrack = v);
	}

/* === Instance Fields === */

	public var player : Player;

	public var playbackProperties : PlayerPlaybackProperties;
	public var playlist : Playlist;
	public var history : PlayerHistory;

	// session name, assigned when session is saved or loaded
	public var name : Null<String>;

	//public var trackChange : Signal<Delta<Null<Track>>>;
	// fired after the change in focus has been made
	public var trackChanged : Signal<Delta<Null<Track>>>;
	// fired just before focus shifts to a different Track
	public var trackChanging : Signal<Delta<Null<Track>>>;
}

@:structInit
class LoadCallbackOptions {
/* === Fields === */
    @:optional public var trigger : LoadTrigger;
    @:optional public var manipulate : PlaybackDriver->Void;
    @:optional public var ready : Void->Void;
    @:optional public var attached : Void->Void;
    @:optional public var error : Dynamic->Void;

/* === Computed Fields === */

}

/*
typedef LoadCallbackOptions = {
    @:optional var trigger : LoadTrigger;
	@:optional function manipulate(controller : PlaybackDriver):Void;
	@:optional function ready():Void;
	@:optional function attached():Void;
	@:optional function error(error : Dynamic):Void;
};
*/
