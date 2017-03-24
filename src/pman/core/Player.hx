package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.http.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.Random;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.media.MediaReadyState;

import electron.ext.App;
import electron.ext.Dialog;
import electron.ext.FileFilter;
import electron.ext.NativeImage;

import pman.core.PlayerSession;
import pman.core.PlayerMediaContext;
import pman.core.PlayerStatus;
import pman.display.*;
import pman.display.media.*;
import pman.media.*;
import pman.ui.*;
import pman.ui.PlayerMessageBoard;
import pman.db.PManDatabase;
import pman.ds.*;

import tannus.math.TMath.*;
import foundation.Tools.*;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.RandomTools;
using pman.media.MediaTools;
using pman.core.PlayerTools;

class Player extends EventDispatcher {
	/* Constructor Function */
	public function new(main:BPlayerMain, page:PlayerPage):Void {
	    super();

		app = main;
		this.page = page;

		// the app's color scheme
		theme = new ColorScheme();

		// create the Player's view
		view = new PlayerView( this );

		// create the Player's Session
		session = new PlayerSession( this );

		// create the ready-state fields
		isReady = false;
		readyEvent = new VoidSignal();
		readyEvent.once(function() isReady = true);

		// listen for 'trackChange' events
		session.trackChanged.on( _onTrackChanged );
		session.trackChanging.on( _onTrackChanging );
	}

/* === Instance Methods === */

	/**
	  * attach [this] Player to the given Stage
	  */
	public function attachToStage(stage : Stage):Void {
		stage.addChild( view );

		initialize( stage );
	}

	/**
	  * initialize [this] Player, once it has been given a view
	  */
	private function initialize(stage : Stage):Void {
	    var ad = app.appDir;
	    if (ad.hasSavedPlaybackSettings()) {
	        ad.loadPlaybackSettings(this, function() {
	            readyEvent.fire();
	        });
	    }
        else {
            defer( readyEvent.fire );
        }
	}

	/**
	  * post a Message to the message board
	  */
	public inline function message(msg : EitherType<String, MessageOptions>):Void {
		view.messageBoard.post( msg );
	}

	/**
	  * Create a PromptBox, to prompt the user for information
	  */
	public function prompt(msg:String, ?placeholder:String, callback:Null<String>->Void):Void {
		var box = new PromptBox();
		box.title = msg;
		if (placeholder != null) {
			box.placeholder = placeholder;
		}
		box.open();
		box.readLine(function(text : String) {
			text = text.trim();
			if (text.empty()) {
				callback( null );
			}
			else {
				callback( text );
			}
			box.close();
		});
		box.focus();
	}

	/**
	  * show playlist view
	  */
	public inline function showPlaylist():Void {
		page.openPlaylistView();
	}

	/**
	  * hide playlist view
	  */
	public inline function hidePlaylist():Void {
		page.closePlaylistView();
	}

	/**
	  * test whether the playlist view is open
	  */
	public inline function isPlaylistOpen():Bool {
		return page.isPlaylistViewOpen();
	}

	/**
	  * toggle the playlist view
	  */
	public inline function togglePlaylist():Void {
	    page.togglePlaylistView();
	}

	/**
	  * obtain reference to playlist view
	  */
	public inline function getPlaylistView():Null<PlaylistView> return page.playlistView;

	/**
	  * save current player-state to the filesystem
	  */
	public function saveState(saveAs:Bool=false, ?done:Void->Void):Void {
	    inline function finish()
	        if (done != null)
	            defer( done );
	    if (session.name == null || saveAs) {
            prompt('session title', null, function(title) {
                if (title == null) {
                    finish();
                }
                else {
                    _saveState( title );
                    session.name = title;
                    finish();
                }
            });
        }
        else {
            _saveState( session.name );
        }
	}

	/**
	  * load the saved player-state from the filesystem
	  */
	public inline function loadState(name:String, ?done:Void->Void):Void {
	    _loadState(name, done);
	}

	/**
	  * save the current session to the filesystem
	  */
	public inline function _saveState(name : String):Void {
	    app.appDir.saveSession(name, session.toJson());
	}

	/**
	  * load a saved session by name
	  */
	public inline function _loadState(name:String, ?done:Void->Void):Void {
	    session.pullJson(app.appDir.loadSession(name), function() {
	        session.name = name;
	        if (page.playlistView != null) {
	            page.playlistView.refresh();
	        }
	        if (done != null)
	            done();
	    });
	}

	/**
	  * save the current playlist to a file
	  */
	public function savePlaylist(?done : Void->Void):Void {
	    Dialog.showSaveDialog({
            title: 'Export a Muthafuckin\' Playlist',
            buttonLabel: 'Save',
            defaultPath: Std.string(App.getPath( Videos ).plusString( 'playlist.m3u' )),
            filters: [FileFilter.PLAYLIST]
	    }, function( spath ) {
	        var path:Path = new Path( spath );
	        if (path.extension == '') {
	            path.extension = 'm3u';
	        }
            else if (path.extension != 'm3u') {
                throw 'not implemented';
            }
            else {
                var file = new File( path );
                var encoder = new pman.format.m3u.Writer();
                file.write(encoder.encode( session.playlist ));
                message({
                    text: 'Playlist exported',
                    fontSize: '10pt'
                });
                if (done != null) {
                    defer(done);
                }
            }
	    });
	}

	/**
	  * get the current player status
	  */
	@:access( pman.media.LocalMediaObjectPlaybackDriver )
	public function getStatus():PlayerStatus {
	    var status : PlayerStatus;
	    if (session.hasMedia()) {
	        if (Std.is(session.playbackDriver, LocalMediaObjectPlaybackDriver)) {
                var mo:MediaObject = cast(cast(session.playbackDriver, LocalMediaObjectPlaybackDriver<Dynamic>).mediaObject, MediaObject);
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
	    return status;
	}

/* === Media Methods === */

	/**
	  * load, switch to, and play the given Track
	  */
	public function openTrack(track:Track, ?cb:OpenCbOpts):Void {
		if (cb == null) {
			cb = {};
		}
		// check whether we're actively playing
		var playing:Bool = (!paused && session.hasMedia());

		// load the new Track
		session.load(track, {
            trigger: 'user',
			attached: function() {
				if (cb.attached != null) {
					cb.attached();
				}
			},
			manipulate: function(mc : MediaController) {
				if (cb.startTime != null) {
					mc.setCurrentTime( cb.startTime );
				}
				if (cb.manipulate != null) {
					cb.manipulate( mc );
				}
			},
			ready: function() {
				if ( playing ) {
					play();
				}
				if (cb.ready != null) {
					cb.ready();
				}
			}
		});
	}

	public inline function openMedia(provider:MediaProvider, ?cb:OpenCbOpts):Void {
		openTrack(new Track( provider ), cb);
	}

/* === System Methods === */

	/**
	  * wait until Player is ready
	  */
	public function onReady(callback : Void->Void):Void {
		if ( isReady ) {
			defer( callback );
		}
		else {
			readyEvent.once(function() {
				defer( callback );
			});
		}
	}

	/**
	  * add the Media referred to by the given paths to the Session
	  */
	public function addPathsToSession(paths : Array<String>):Void {
		trace( paths );
	}

	/**
	  * capture snapshot of media
	  */
	public function snapshot():Void {
	    // first off, check whether there's even anything to take a 'snapshot' of
	    if (session.hasMedia()) {

	    }
	}

    // get media object
    @:access( pman.media.LocalMediaObjectPlaybackDriver )
	private function gmo():Null<MediaObject> {
	    var pd = session.playbackDriver;
	    if (pd == null) {
	        return null;
	    }
        else {
            if (Std.is(pd, pman.media.LocalMediaObjectPlaybackDriver)) {
                return cast(cast(pd, LocalMediaObjectPlaybackDriver<Dynamic>).mediaObject, MediaObject);
            }
            else {
                return null;
            }
        }
	}

	/**
	  * prompt the user to select media files
	  */
	public function selectFiles(callback : Array<File> -> Void):Void {
		// middle-man callback to map the paths to File objects
		function _callback(paths : Array<String>):Void {
			// ... why did I do this?
			//callback(paths.filter( Fs.exists ).map.fn([path] => new File(new Path( path ))));
			callback(paths.map.fn([path] => new File(new Path( path ))));
		}
		app.fileSystemPrompt({
			title: 'Select one or more files to open',
			buttonLabel: 'Open That Shit',
			filters: [FileFilter.ALL, FileFilter.VIDEO, FileFilter.AUDIO, FileFilter.PLAYLIST]
		}, _callback);
	}

	/**
	  * prompt the user to select a directory
	  */
	public function selectDirectory(callback : Array<Directory> -> Void):Void {
		function _callback(paths : Array<String>):Void {
			var dirs = [];
			for (path in paths) {
				if (Fs.exists( path ) && Fs.isDirectory( path )) {
					dirs.push(new Directory(new Path( path )));
				}
			}
			callback( dirs );
		}
		app.fileSystemPrompt({
			title: 'Select a Directory to open',
			buttonLabel: 'Open That Shit',
			directory: true
		}, _callback);
	}

	/**
	  * prompt the user to select a Directory, extract all Media files from that directory, and
	  * build a Playlist from them
	  */
	public function selectDirectoryToPlaylist(callback : Array<Track>->Void):Void {
		selectDirectory(function( dirs ) {
			if (dirs.empty()) {
				callback([]);
			}
			else {
			    dirs[0].getAllOpenableFiles(function( files ) {
			        callback(files.convertToTracks());
			    });
			}
		});
	}

	/**
	  * prompt user to select some files, and build Playlist out of results
	  */
	public function selectFilesToPlaylist(callback : Array<Track>->Void):Void {
		selectFiles(function( files ) {
		    callback(files.convertToTracks());
		});
	}

	/**
	  * prompt the user to input one or more Urls
	  */
	public function promptForAddresses(callback : Array<String> -> Void):Void {
		prompt('Enter Address:', 'http://www.website.com/path/to/video.mp4', function(text : String) {
			text = text.trim();
			var url:Url = new Url( text );
			url = _map_address( url );
			callback([url]);
		});
	}
	public inline function selectAddresses(f : Array<String> -> Void):Void promptForAddresses( f );

	/**
	  * prompt the user for media addresses, and create a Playlist from them
	  */
	public function selectAddressesToPlaylist(callback : Array<Track>->Void):Void {
		selectAddresses(function(urls) {
			callback(urls.map.fn(Track.fromUrl( _ )));
		});
	}

	/**
	  * select files and add them to the queue
	  */
	public function selectAndOpenFiles(?done : Array<Track>->Void):Void {
		selectFilesToPlaylist(function( tracks ) {
			addItemList(tracks, function() {
				if (done != null) {
					done( tracks );
				}
			});
		});
	}

	/**
	  * select entirety of a Directory and add them to the queue
	  */
	public function selectAndOpenDirectory(?done : Array<Track>->Void):Void {
		selectDirectoryToPlaylist(function( tracks ) {
			addItemList(tracks, function() {
				if (done != null) {
					done( tracks );
				}
			});
		});
	}

	/**
	  * select urls, and add them to the queue
	  */
	public function selectAndOpenAddresses(?done : Array<Track>->Void):Void {
		selectAddressesToPlaylist(function( tracks ) {
			addItemList(tracks, function() {
				if (done != null) {
					done( tracks );
				}
			});
		});
	}

	/**
	  * transforms common urls that do not point to media files directly into urls that do
	  */
	private function _map_address(url : Url):Url {
		return url;
	}

	/**
	  * add a single media item to the queue
	  */
	public inline function addItem(item : Track):Void {
		session.addItem( item );
	}

	/**
	  * add a batch of media items to the queue
	  */
	public function addItemList(items:Array<Track>, ?done:Void->Void):Void {
	    // initialize these items
	    items.initAll(function() {
            // if these are the first items added to the queue, autoLoad will be invoked once they are all added
            var autoLoad:Bool = session.playlist.empty();
            var willPlay:Null<Track> = null;
            if ( autoLoad ) {
                willPlay = items[0];
            }

            // shuffle the tracks
            if ( session.pp.shuffle ) {
                var rand = new Random();
                items = rand.shuffle( items );
            }

            // add all the items
            for (item in items) {
                session.addItem(item, null, false);
            }

            // autoPlay if appropriate
            if (autoLoad && willPlay != null) {
                openTrack(willPlay, {
                    attached: function() {
                        //trace('Media linked to player by auto-load');
                        if (done != null) done();
                    }
                });
            }
            else {
                if (done != null) {
                    defer( done );
                }
            }
        });
	}

	/**
	  * clear the playlist
	  */
	public function clearPlaylist():Void {
		session.playlist.clear();
		stop();
		if (session.hasMedia()) {
			session.blur();
		}
	}

	/**
	  * get a media item by it's index in the playlist
	  */
	public inline function getTrack(index : Int):Null<Track> {
		//return session.playlist[index];
		return session.playlist[index];
	}

	/**
	  * get the media item by offset from current media item
	  */
	public inline function getTrackByOffset(offset : Int):Null<Track> {
        return getTrack(session.indexOfCurrentMedia() + offset);
		//return session.playlist.getByOffset(session.focusedTrack, offset);
	}

	/**
	  * get the media item after the current one in the queue
	  */
	public inline function getNextTrack():Null<Track> {
		return getTrackByOffset( 1 );
	}
	
	/**
	  * get the media item before the current one in the queue
	  */
	public inline function getPreviousTrack():Null<Track> {
		return getTrackByOffset( -1 );
	}

	/**
	  * when the focus has just changed
	  */
	private function _onTrackChanged(delta : Delta<Null<Track>>):Void {
		if (delta.current == null) {
			app.title = 'PMan';
		}
		else {
			var newTrack:Track = delta.current;
			app.title = 'PMan | ${newTrack.title}';

			// update the database regarding the Track that has just come into focus
			var ms = app.db.mediaStore;

			var mip = ms.cogMediaItem( newTrack.uri );
			mip.then(function( item ) {
			    // jump to saved time
			    /*
			    item.getInfo(function(info) {
			        if (info.time.last != null) {
			            defer(function() {
			                currentTime = info.time.last;
			            });
			        }
                    else if (info.time.start != null) {
                        defer(function() {
			                currentTime = info.time.start;
                        });
                    }
			    });
			    */
			});
			mip.unless(function(error) {
			    app.errorMessage( error );
			});
		}

		// automatically save the playback settings
		app.appDir.savePlaybackSettings( this );
	}

    /**
      * current Track is about to lose focus and be replaced by a new one
      */
	private function _onTrackChanging(delta : Delta<Null<Track>>):Void {
		if (delta.previous == null) {
			null;
		}
		else {
            var track:Track = delta.previous;
			var nums:Array<Float> = [currentTime, durationTime];
			var atend:Bool = ended;

            // get the media_item for the Track
			var ms = app.db.mediaStore;
			var mip = ms.cogMediaItem( track.uri );
			mip.then(function( item ) {
			    // save the current time
			    item.getInfo(function( info ) {
			        if ( !atend ) {
                        info.time.last = nums[0];
                    }
                    else {
                        info.time.last = null;
                    }
			        info.push();
			    });
			});
			mip.unless(function( error ) {
			    app.errorMessage( error );
			});
		}
	}

/* === Playback Methods === */

	/**
	  * start playback of media
	  */
	public function play():Void {
		sim(_.play());
	}
	
	/**
	  * pause playback of media
	  */
	public function pause():Void {
		sim(_.pause());
	}

	/**
	  * stop playback of media; this cannot be undone
	  */
	public function stop():Void {
		sim(_.stop());
	}

	/**
	  * toggle the media's playback
	  */
	public function togglePlayback():Void {
		sim(_.togglePlayback());
	}

	/**
	  * query the fullscreen status of [this] Player's window
	  */
	public inline function isFullscreen():Bool {
		return app.browserWindow.isFullScreen();
	}

	/**
	  * set the fullscreen status of [this] Player's window
	  */
	public inline function setFullscreen(flag : Bool):Void {
		app.browserWindow.setFullScreen( flag );
	}

	/**
	  * goto a Track
	  */
	public function gotoTrack(index:Int, ?cb:OpenCbOpts):Void {
		// handle empty Player
		if (!session.hasMedia()) {
			return ;
		}
		var track = getTrack( index );
		if (track == null) {
			return ;
		}
		openTrack(track, cb);
	}

	/**
	  * goto a Track
	  */
	public function gotoByOffset(offset:Int, ?cb:OpenCbOpts):Void {
		// handle empty Player
		if (!session.hasMedia()) {
			return ;
		}

		// get the media item
		var track:Null<Track> = getTrackByOffset( offset );

		// attempt to resolve missing track
		if (track == null) {
			if (offset == 0) {
				return ;
			}
			// positive offset, meaning there is no 'next' track
			else if (offset > 0) {
				track = getTrack( 0 );
			}
			// negative offset, meaning there is no 'prev' track
			else if (offset < 0) {
				track = getTrack(session.playlist.length - 1);
			}

			// handle failed resolution
			if (track == null) {
				return ;
			}
		}

		// load the track
		openTrack(track, cb);
	}

	/**
	  * goto the next track
	  */
	public inline function gotoNext(?cb : OpenCbOpts):Void {
		gotoByOffset(1, cb);
	}
	public inline function gotoPrevious(?cb : OpenCbOpts):Void {
		gotoByOffset(-1, cb);
	}

/* === Computed Instance Fields === */

	public var duration(get, never):Duration;
	private inline function get_duration():Duration return sim(_.getDuration(), new Duration());

	public var durationTime(get, never):Float;
	private inline function get_durationTime():Float return sim(_.getDurationTime(), 0);

	public var paused(get, never):Bool;
	private inline function get_paused():Bool return sim(_.getPaused(), true);

	public var currentTime(get, set):Float;
	private inline function get_currentTime():Float return sim(_.getCurrentTime(), 0.0);
	private inline function set_currentTime(v : Float):Float {
		sim(_.setCurrentTime( v ));
		return currentTime;
	}

	public var volume(get, set):Float;
	private inline function get_volume():Float return session.pp.volume;
	private inline function set_volume(v : Float):Float return (session.pp.volume = v);

	public var playbackRate(get, set):Float;
	private inline function get_playbackRate():Float return session.pp.speed;
	private inline function set_playbackRate(v : Float):Float return (session.pp.speed = v);

	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return session.pp.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (session.pp.shuffle = v);

	public var muted(get, set):Bool;
	private inline function get_muted():Bool return sim(_.getMuted(), false);
	private inline function set_muted(v : Bool):Bool {
		sim(_.setMuted( v ));
		return muted;
	}

	public var ended(get, never):Bool;
	private inline function get_ended():Bool return sim(_.getEnded(), false);

	public var track(get, never):Null<Track>;
	private inline function get_track():Null<Track> return session.focusedTrack;

/* === Instance Fields === */

	public var app : BPlayerMain;
	public var page : PlayerPage;
	public var theme : ColorScheme;
	public var view : PlayerView;
	public var session : PlayerSession;
	public var isReady(default, null): Bool;

	private var readyEvent : VoidSignal;
}

typedef OpenCbOpts = {
	@:optional function manipulate(mc : MediaController):Void;
	@:optional function ready():Void;
	@:optional function attached():Void;

	@:optional var startTime : Float;
};
