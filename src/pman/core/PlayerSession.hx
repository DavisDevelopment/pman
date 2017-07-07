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
import pman.core.PlaybackTarget;
import pman.async.*;

import foundation.Tools.*;
import electron.Tools.*;
import pman.Globals.*;
import Slambda.fn;

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
using pman.async.VoidAsyncs;

/**
  * Object used to represent the current media Playback context
  */
@:allow( pman.core.Player )
@:access( pman.core.PlayerTab )
class PlayerSession {
	/* Constructor Function */
	public function new(p : Player):Void {
		player = p;

		playbackProperties = new PlayerPlaybackProperties(1.0, 1.0, false);

		trackChanging = new Signal();
		trackChanged = new Signal();
		trackReady = new Signal();
		targetChanged = new Signal();
		target = PTThisDevice;

		tabs = [new PlayerTab( this )];
		activeTabIndex = 0;

        player.onReady( _listen );
	}

/* === Instance Methods === */

	/**
	  * get the index of the currently playing media
	  */
	public inline function indexOfCurrentMedia():Int {
	    return (focusedTrack != null ? playlist.indexOf( focusedTrack ) : -1);
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
	    (shuffle?playlist.shuffledPush:playlist.push)( track );
	}

	/**
	  * mount the given Track, and switch focus to it
	  */
	public function focus(track:Track, ?done:Void->Void):Void {
		var prev = focusedTrack;
		var pre_delta:Delta<Null<Track>> = new Delta(track, prev);
		trackChanging.call( pre_delta );
		if (focusedTrack != null && focusedTrack.isMounted()) {
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
			tab.blurredTrack = focusedTrack;
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
		return (focusedTrack != null);
	}

	/**
	  * encode [this] Session to a String
	  */
	public function encode():String {
	    // prepare the Serializer
	    var serializer = new Serializer();
	    serializer.useCache = true;
	    inline function w(x:Dynamic)
	        serializer.serialize( x );

	    // write the data
	    w( tabs.length );
	    w( activeTabIndex );
	    for (tab in tabs) {
	        tab.hxSerialize( serializer );
	    }

	    return serializer.toString();
	}

	/**
	  * decode the given String to 
	  */
	public function decode(s:String, ?done:VoidCb):Void {
	    var us = new Unserializer( s );
	    inline function v():Dynamic return us.unserialize();

	    var ntabs:Int = v(), tabi:Int = v();
	    tabs = [];
	    for (i in 0...ntabs) {
	        var tab = new PlayerTab( this );
	        tab.hxUnserialize( us );
	        tabs.push( tab );
	    }

        var tasks:Array<VoidAsync> = [
            (function(next) {
                var utracks:Set<Track> = new Set();
                for (t in tabs) {
                    utracks.pushMany( t.playlist );
                }
                var loader = new pman.async.tasks.TrackListDataLoader();
                loader.load(utracks.toArray(), function(?error, ?result) {
                    trace( result );
                });
                defer(next.void());
            }),
            (function(next) {
                defer(function() {
                    setTab( tabi );
                    next();
                });
            })
        ];

        if (done == null)
            done = untyped fn(err => if (err != null) (untyped __js__('console.error')( err )));

        tasks.series(function(?error : Dynamic) {
            //if (error != null)
                //(untyped __js__('console.error')( error ));
            done( error );
        });
	}

	/**
	  * get state
	  */
	public function getState_():PlayerSessionState {
	    var state = new PlayerSessionState();
	    state.pull( this );
	    return state;
	}

	/**
	  * put a state onto [this]
	  */
	public function pullState_(state:PlayerSessionState, ?done:VoidCb):Void {
	    var stack:Array<VoidAsync> = new Array();

	    // pull the playlist
	    stack.push(function(next) {
            var tmp = player.shuffle;
	        player.shuffle = false;
	        player.addItemList(state.playlist.toTracks(), function() {
                player.shuffle = tmp;
                next();
	        });
	    });

	    // pull the current track
	    stack.push(function(next) {
	        if (state.focused != -1) {
	            player.gotoTrack(state.focused, {
                    attached: function() {
                        next();
                    }
	            });
	        }
	    });

	    if (done == null) {
	        done = function(?error:Dynamic):Void {
	            if (error != null)
	                throw error;
	        };
	    }

	    stack.series( done );
	}

	/**
	  * save state
	  */
	public inline function save():Void {
	    Fs.write(filePath(), encode());
	}

	/**
	  * load state
	  */
	public function restore(?done : VoidCb):Void {
	    // if the File exists
	    if (hasSavedState()) {
	        // decode the state
			//var state = PlayerSessionState.decode(Fs.read(filePath()));
	        // pull the state onto [this] Session
			//pullState(state, done);
			decode(Fs.read(filePath()), done);
	    }
        else {
            if (done != null) {
                defer(done.void());
            }
        }
	}

	/**
	  * check whether there is a session.dat file
	  */
	public function hasSavedState():Bool {
		return FileSystem.exists(filePath());
	}

	/**
	  * delete the session.dat file
	  */
	public function deleteSavedState():Void {
	    try {
            FileSystem.deleteFile(filePath());
        }
        catch (error : Dynamic) {
            return ;
        }
	}

	/**
	  * save the PlaypackProperties
	  */
	public function savePlaybackSettings():Void {
	    Fs.write(psPath(), encodePlaybackSettings());
	}

	/**
	  * load the PlaybackProperties
	  */
	public function loadPlaybackSettings():Void {
	    try {
	        var data = Fs.read(psPath());
	        var props = decodePlaybackSettings( data );
	        playbackProperties.rebase( props );
	    }
	    catch (error : Dynamic) {
	        return ;
	    }
	}

	/**
	  * encode PlaybackProperties
	  */
	public function encodePlaybackSettings():ByteArray {
	    var s = new Serializer();
	    playbackProperties.hxSerialize( s );
	    return ByteArray.ofString(s.toString());
	}

	/**
	  * decode PlaybackProperties
	  */
	public function decodePlaybackSettings(data : ByteArray):PlayerPlaybackProperties {
	    var u = new Unserializer(data.toString());
	    var i = Type.createEmptyInstance( PlayerPlaybackProperties );
	    i.hxUnserialize( u );
	    return i;
	}

	/**
	  * create a new tab
	  */
	public function newTab(?f : PlayerTab -> Void):Int {
	    var nt = new PlayerTab( this );
	    tabs.push( nt );
	    if (f != null)
	        f( nt );
	    return (tabs.length - 1);
	}

	/**
	  * switch active tabs
	  */
	public function setTab(tabIndex : Int):PlayerTab {
	    if (tabs[tabIndex] == null)
	        return activeTab;
	    if (tabIndex != activeTabIndex) {
	        player.dispatch('tabswitching', null);
	        blur();
	        activeTabIndex = tabIndex;
	        if (activeTab.blurredTrack != null) {
	            focus( tab.blurredTrack );
	            tab.blurredTrack = null;
            }
            else if (activeTab.playlist.length > 0) {
                focus(activeTab.playlist[0]);
            }
	        player.dispatch('tabswitched', null);
	    }
        else if (activeTab.blurredTrack != null) {
            focus( activeTab.blurredTrack );
            activeTab.blurredTrack = null;
        }
	    return activeTab;
	}

	/**
	  * close a Tab
	  */
	public function deleteTab(tabIndex : Int):Bool {
	    if (tabs[tabIndex] == null) {
	        return false;
	    }
        else {
            var t = tabs[tabIndex];
            var ct = tabs[activeTabIndex];
            if (tabIndex == activeTabIndex) {
                if (tabs.length == 1) {
                    //TODO
                }
                else {
                    var newIndex:Int = (tabIndex - 1);
                    if (tabs[newIndex] == null)
                        newIndex = (tabIndex + 1);
                    ct = tabs[newIndex];
                }
            }
            var newtabs = tabs.filter.fn(_ != t);
            var newIndex = tabs.indexOf( ct );
            setTab( newIndex );
            tabs = newtabs;
            activeTabIndex = tabs.indexOf( ct );
            return true;
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
	    // on any change to the playback properties
	    playbackProperties.changed.on(function( change ) {
	        // save the playback settings
	        savePlaybackSettings();

	        switch ( change ) {
                case Volume( d ):
                    player.dispatch('change:volume', d);

                case Speed( d ):
                    player.dispatch('change:speed', d);

                case Shuffle( nv ):
                    player.dispatch('change:shuffle', nv);

                case Muted( nv ):
                    player.dispatch('change:muted', nv);

				case Repeat( nv ):
                    player.dispatch('change:repeat', nv);

                case Scale( d ):
                    player.dispatch('change:scale', d);
	        }
	    });

	    // on focusedTrack changing
	    trackChanged.on(function( d ) {
	        // forward the event to the Player
	        player.dispatch('change:nowPlaying', d);
	        // save [this] Session
	        player.saveState();
	    });

	    // when the Playlist changes
	    playlist.changeEvent.on(function( change ) {
	        // save [this] Session
	        player.saveState();
	    });

        // when the window is about to close
	    player.app.closingEvent.on(function(event, stack) {
	        stack.push(function(next) {
	            if (player.track == null) {
	                defer( next );
	            }
                else {
                    player.track.editData(function( i ) {
                        i.setLastTime( player.currentTime );
                    }, next);
                }
	        });
	        stack.push(function(next) {
	            defer(function() {
	                player.saveState();
	                next();
	            });
	        });
	    });

	    targetChanged.on( _onTargetChanged );

        // handle tab switching events
        player.on('tabswitching', untyped function() {
            //
        });
	    player.on('tabswitched', untyped function() {
	        var plView = player.getPlaylistView();
	        if (plView != null) {
	            plView.refresh();
	        }
	    });
	}

	/**
	  * get the Path to the session.dat file
	  */
	private static inline function filePath():Path {
	    return BPlayerMain.instance.appDir.lastSessionPath();
	}

    /**
      * get the Path to the playback properties file
      */
	private static inline function psPath():Path {
	    return bpmain.appDir.playbackSettingsPath();
	}

	/**
	  * handle changes to 'target'
	  */
	@:access( pman.media.Track )
	private function _onTargetChanged(delta : Delta<PlaybackTarget>):Void {
	    switch (delta.toPair()) {
            case [PTThisDevice, PTChromecast( cc )]:
                if (focusedTrack != null) {
                    focusedTrack.driver = new ChromecastPlaybackDriver( cc );
                }

            case [PTChromecast(_), PTThisDevice]:
                if (focusedTrack != null) {
                    var t = focusedTrack;
                    blur( t );
                    focus( t );
                }

            default:
                return ;
	    }
	}

/* === Computed Instance Fields === */

    // the currently active Tab
	public var activeTab(get, never):Null<PlayerTab>;
	private inline function get_activeTab() return tabs[activeTabIndex];

	// alias to [activeTab]
	public var tab(get, never):Null<PlayerTab>;
	private inline function get_tab() return activeTab;

	public var pp(get, never):PlayerPlaybackProperties;
	private inline function get_pp():PlayerPlaybackProperties return playbackProperties;

	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return pp.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (pp.shuffle = v);

	public var muted(get, set):Bool;
	private inline function get_muted():Bool return pp.muted;
	private inline function set_muted(v : Bool):Bool return (pp.muted = v);

	public var repeat(get, set):RepeatType;
	private inline function get_repeat():RepeatType return pp.repeat;
	private inline function set_repeat(v : RepeatType):RepeatType return (pp.repeat = v);

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
	public var focusedTrack(get, set): Null<Track>;
	private inline function get_focusedTrack() return tab.focusedTrack;
	private inline function set_focusedTrack(v) return (tab.focusedTrack = v);

	public var playlist(get, set):Playlist;
	private inline function get_playlist() return tab.playlist;
	private inline function set_playlist(v) return (tab.playlist = v);

	public var target(default, set):PlaybackTarget;
	private function set_target(v) {
	    var old = target;
	    var res = (target = v);
	    defer(targetChanged.call.bind(new Delta(res, old)));
	    return res;
	}

/* === Instance Fields === */

	public var player : Player;
	public var playbackProperties : PlayerPlaybackProperties;
	//public var playlist : Playlist;

	public var history : PlayerHistory;

	// session name, assigned when session is saved or loaded
	public var name : Null<String>;
	public var activeTabIndex : Int;
	public var tabs : Array<PlayerTab>;

	//public var trackChange : Signal<Delta<Null<Track>>>;
	// fired after the change in focus has been made
	public var trackChanged : Signal<Delta<Null<Track>>>;
	// fired just before focus shifts to a different Track
	public var trackChanging : Signal<Delta<Null<Track>>>;
	// fired once the Player has prepared a Track
	public var trackReady : Signal<Track>;
	// fired when 'target' changes
	public var targetChanged : Signal<Delta<PlaybackTarget>>;
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
