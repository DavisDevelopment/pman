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
import tannus.async.*;

import edis.Globals.*;
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
using tannus.async.Asyncs;
using tannus.FunctionTools;
using tannus.html.JSTools;

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
	    return activeTab.indexOfCurrentMedia();
	}

	/**
	  * remove a Media item from the queue
	  */
	public inline function removeItem(track : Track):Bool {
	    return tab.removeTrack( track );
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
		//(shuffle ? playlist.shuffledPush : playlist.push)( track );
	    playlist.callprop((shuffle ? 'shuffledPush' : 'push'), [track]);
	}

	/**
	  * mount the given Track, and switch focus to it
	  */
	public function focus(track:Track, ?done:VoidCb):Void {
	    // ensure that [done] is non-null
	    if (done == null)
	        done = VoidCb.noop;

	    // define var for previously focused track
		var prev:Null<Track> = focusedTrack;

		// create object to describe the change of focus
		var pre_delta:Delta<Null<Track>> = new Delta(track, prev);

		// fire off signal for change in focus
		trackChanging.call( pre_delta );

		// create list to hold asynchronous actions
		var steps:Array<VoidAsync> = new Array();

		// defocus ("blur") the current track
		if (focusedTrack != null && focusedTrack.isMounted()) {
			blur( focusedTrack );
		}

        // draw focus to ("mount") [track]
		_mountIfNecessary(track, function(?error) {
			focusedTrack = track;
			player.view.attachRenderer(track.renderer, function(?error) {
			    if (error != null) {
			        done( error );
			    }
                else {
                    var post_delta:Delta<Null<Track>> = new Delta(focusedTrack, prev);
                    trackChanged.call( post_delta );
                    done();
                }
            });
		});
	}

	/**
	  * dismount the given Track, and shift focus off of it
	  */
	public function blur(?track:Track, ?done:VoidCb):Void {
	    if (done == null)
	        done = VoidCb.noop;

	    vsequence(function(push, exec) {
		// if [track] is not explicitly provided
		if (track == null) {
			// default to [focusedTrack]
			if (hasMedia()) {
				track = focusedTrack;
			}
			// if [focusedTrack] is null
			else {
				// then I guess we're done?
				return exec();
			}
		}

		// if [track] is already unmounted, then it cannot be focused, and thus cannot be blurred
		if (!track.isMounted()) {
			return exec('Error: Track is not mounted, and thus cannot be blurred');
		}

        // announce immenent change in focus
		var pre_delta = new Delta(null, track);
		trackChanging.call( pre_delta );

		// dismount the Track
		push( track.dismount );

		// unlink the Track
		if (track == focusedTrack) {

			push( player.view.detachRenderer );
			tab.blurredTrack = focusedTrack;
			focusedTrack = null;

            push(function() {
                var post_delta = new Delta(null, track);
                trackChanged.call( post_delta );
            }.toAsync());
		}

		exec();
        }, done);
	}

	/**
	  * either mounts [track], and invokes [done] when that has completed,
	  * or simply invokes [done] as soon as the current callStack has finished,
	  * if [track] is already mounted
	  */
	private function _mountIfNecessary(track:Track, done:VoidCb):Void {
		if (track.isMounted()) {
			defer(done.void());
		}
		else {
			track.mount(function(?error):Void {
				if (error != null) {
					report( error );
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

		// shift focus to [t]
		focus(t, function(?error) {
		    if (error != null) {
		        if (cb.error != null) {
                    return cb.error( error );
                }
                else {
                    throw error;
                }
		    }
            else if (cb.attached != null) {
				defer( cb.attached );
			}

			var d = focusedTrack.driver;
			if (cb.manipulate != null && t.hasFeature(LoadedMetadataEvent)) {
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
				var cp:Null<VoidSignal> = null;
				if (t.hasFeature( CanPlayEvent )) {
				    cp = d.getCanPlaySignal();
				}
                else if (t.hasFeature( LoadEvent )) {
                    cp = d.getLoadSignal();
                }

                if (cp != null) {
                    cp.once(function() {
                        defer( cb.ready );
                    });
                }
			}
		});
	}

	/**
	  * reassign the playlist field
	  */
	public function setPlaylist(pl: Playlist):Playlist {
		trace('(setPlaylist) betty');
		var ret = tabs[activeTabIndex].setPlaylist( pl );
		refreshPlv();
		return ret;
	}

    /**
      refresh PlaylistView
     **/
	inline function refreshPlv() {
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
	    // create a new Unserializer
	    var us = new Unserializer( s );

	    // shorthand function for getting a value from that Unserializer
	    inline function v():Dynamic return us.unserialize();

	    var ntabs:Int = v(), tabi:Int = v();
	    tabs = [];
	    for (i in 0...ntabs) {
	        var tab = new PlayerTab( this );
	        tab.hxUnserialize( us );
	        tabs.push( tab );
	    }

        var tasks:Array<VoidAsync> = [
            (function(next: VoidCb):Void {
                // container to put Tracks into
                var utracks:Set<Track> = new Set();

                // iterate over the tabs
                for (t in tabs) {
                    // push the list of tracks from [t] into [utracks]
                    utracks.pushMany( t.playlist );
                }

                // create a new data loader
                var loader = new pman.async.tasks.EfficientTrackListDataLoader(utracks.toArray(), player.app.db.mediaStore);

                // run the loader
                loader.run(function(?error) {
                    // report any errors that may occur
                    if (error != null) {
                        #if debug 
                        throw error;
                        #else
                        report( error );
                        #end
                    }
                });
                // defer announcing completion till the next stack
                defer(next.void());
            }),
            (function(next: VoidCb):Void {
                // defer assigning the tab to the next stack
                defer(function() {
                    setTab( tabi );

                    // announce completion
                    next();
                });
            })
        ];

        // ensure that [done] isn't null
        if (done == null) {
            //done = untyped fn(err => if (err != null) (untyped __js__('console.error')( err )));
            function done(?error: Dynamic):Void {
                if (error != null) {
                    report( error );
                }
            }
        }

        // execute [tasks]
        tasks.series(function(?error : Dynamic) {
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
	public inline function restore(?done : VoidCb):Void {
	    // if the File exists
	    if (hasSavedState()) {
	        // decode it
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
	public inline function hasSavedState():Bool {
		return FileSystem.exists(filePath());
	}

	/**
	  * delete the session.dat file
	  */
	public inline function deleteSavedState():Void {
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
	public inline function savePlaybackSettings():Void {
		appState.save( appState.playback );
	}

	/**
	  * load the PlaybackProperties
	  */
	public inline function loadPlaybackSettings():Void {
	    appState.load(appState.playback);
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
	public function newTab(?f:PlayerTab->Void, ?nt:PlayerTab):Int {
	    if (nt == null)
	        nt = new PlayerTab( this );
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
	        var delta:Delta<PlayerTab> = new Delta(tabs[activeTabIndex], tabs[tabIndex]);
	        player.dispatch('tabswitching', delta);
	        blur();
	        activeTabIndex = tabIndex;
	        if (activeTab.blurredTrack != null) {
	            focus( tab.blurredTrack );
	            tab.blurredTrack = null;
            }
            else if (activeTab.playlist.length > 0) {
                focus(activeTab.playlist[0]);
            }
	        player.dispatch('tabswitched', delta.reverse());
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
                    newTab();
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
	  * move TabView to a new index
	  */
	public function moveTab(tab:PlayerTab, index:Int):Void {
	    var ntl = tabs.copy();
	    ntl.remove( tab );
	    ntl.insert(index, tab);
	    activeTabIndex = ntl.indexOf( tab );
	    tabs = ntl;
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
	    // on change to the playback config
	    appState.playback.on('change', function(property, delta:Delta<Dynamic>) {
	        player.dispatch('change:$property', delta);
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
                    player.track.editData(function(i, nxt) {
                        i.setLastTime( player.currentTime );

                        nxt();
                    }, function(?error) {
                        if (error != null) {
                            throw error;
                        }
                        else {
                            next();
                        }
                    });
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
                    //focusedTrack.driver = new ChromecastMediaDriver( cc );
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

    @:deprecated('PlayerPlaybackProperties has been deprecated in favor of ApplicationState.PlaybackConfig')
	public var pp(get, never):PlayerPlaybackProperties;
	private inline function get_pp():PlayerPlaybackProperties return playbackProperties;

	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return appState.playback.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (appState.playback.shuffle = v);

	public var muted(get, set):Bool;
	private inline function get_muted():Bool return appState.playback.muted;
	private inline function set_muted(v : Bool):Bool return (appState.playback.muted = v);

	public var repeat(get, set):RepeatType;
	private inline function get_repeat():RepeatType return appState.playback.repeat;
	private inline function set_repeat(v : RepeatType):RepeatType return (appState.playback.repeat = v);

	public var mediaProvider(get, never):Null<MediaProvider>;
	private inline function get_mediaProvider():Null<MediaProvider> return mft.ternary(_.provider, null);

	public var media(get, never):Null<Media>;
	private inline function get_media():Null<Media> return mft.ternary(_.media, null);

	public var mediaDriver(get, never):Null<MediaDriver>;
	private inline function get_mediaDriver() return mft.ternary(_.driver, null);

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
    @:optional public var manipulate : MediaDriver->Void;
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
