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
import electron.MenuTemplate;
import electron.ext.Menu;

import pman.core.PlayerSession;
import pman.core.PlayerMediaContext;
import pman.core.PlayerStatus;
import pman.core.PlaybackTarget;
import pman.core.PlayerPlaybackProperties;
import pman.display.*;
import pman.display.media.*;
import pman.media.*;
import pman.media.info.*;
import pman.media.info.Mark;
import pman.ui.*;
import pman.ui.PlayerMessageBoard;
import pman.db.PManDatabase;
import pman.ds.*;
import pman.async.*;
import pman.async.tasks.*;

import tannus.math.TMath.*;
import foundation.Tools.*;
import haxe.extern.EitherType;

using DateTools;
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

		// [this] Player's controller
		controller = new PlayerController( this );

		// the app's color scheme
		theme = new ColorScheme();

		// create the Player's view
		view = new PlayerView( this );

		// create the Player's Session
		session = new PlayerSession( this );

		// [this] Player's list of components
		components = new Array();

		// create the ready-state fields
		isReady = false;
		readyEvent = new VoidSignal();
		readyEvent.once(function() isReady = true);

		// listen for 'trackChange' events
		session.trackChanged.on( _onTrackChanged );
		session.trackChanging.on( _onTrackChanging );
		session.trackReady.on( _onTrackReady );
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
	    var prefs = app.db.preferences;
	    if (ad.hasSavedPlaybackSettings()) {
	        ad.loadPlaybackSettings(this, function() {
	            if ( prefs.autoRestore ) {
                    session.restore(function() {
                        readyEvent.fire();
                    });
                }
                else {
                    defer(function() {
                        if (session.hasSavedState()) {
                            confirm('Restore Previous Session?', function(restore : Bool) {
                                if ( restore ) {
                                    session.restore(function() {
                                        readyEvent.fire();
                                    });
                                }
                                else {
                                    session.deleteSavedState();
                                    readyEvent.fire();
                                }
                            });
                        }
                        else {
                            readyEvent.fire();
                        }
                    });
                }
	        });
	    }
        else {
            defer( readyEvent.fire );
        }
	}

	/**
	  * a frame has passed
	  */
	public function tick():Void {
	    dispatch('tick', null);
	    controller.tick();

	    var time:Float = gryffin.Tools.now;
	    for (c in components) {
	        c.onTick( time );
	    }
	}

	/**
	  * attach a component to [this] Player
	  */
	public function attachComponent(c : PlayerComponent):Void {
	    if (!components.has( c )) {
	        components.push( c );
	        c.onAttached();
	        defer(function() {
	            if (track != null) {
	                c.onTrackChanged(new Delta(track, null));
	                defer(function() {
	                    c.onTrackReady( track );
	                });
	            }
	        });
	    }
	}

	/**
	  * detach a component from [this] Player
	  */
	public function detachComponent(c : PlayerComponent):Bool {
	    var res = components.remove( c );
	    if ( res ) {
	        c.onDetached();
	    }
	    return res;
	}

	/**
	  * 'skim' the current media
	  */
	public function skim():Void {
	    if (!components.any.fn(Std.is(_, pman.core.comp.Skimmer))) {
	        var skimr = new pman.core.comp.Skimmer();
	        attachComponent( skimr );
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
	public function prompt(msg:String, ?placeholder:String, ?value:String, callback:Null<String>->Void):PromptBox {
		var box = new PromptBox();
		box.title = msg;
		if (placeholder != null) {
			box.placeholder = placeholder;
		}
		if (value != null) {
		    box.value = value;
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
		return box;
	}

	/**
	  * prompt the user to confirm a something
	  */
	public function confirm(msg:String, callback:Bool->Void):ConfirmBox {
	    var box = new ConfirmBox();
	    box.prompt(msg, function(v) {
	        box.close();
	        callback( v );
	    });
	    box.open();
	    return box;
	}

	/**
	  * open and initiate a QuickOpen prompt
	  */
	public function qoprompt():Void {
	    var box = new QuickOpenPrompt();
	    box.init(function() {
	        box.prompt(function() {

	        });
	    });
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
	  * open the Bookmark editor
	  */
	public function editBookmarks():Void {
	    if (track == null)
	        return ;

	    var editor = new BookmarkEditor(this, track);
	    editor.open();
	    editor.once('close', function(e) {
	        editor.destroy();
	    });
	}

	/**
	  * save current playlist to the filesystem
	  */
	public function savePlaylist(saveAs:Bool=false, ?name:String, ?done:Void->Void):Void {
	    trace(untyped [saveAs, name, done]);
        var l:Playlist = session.playlist;

        if (name != null) {
            session.name = name;
        }

	    function finish():Void {
	        var plf = app.appDir.playlistFile( session.name );
	        var data = pman.format.xspf.Writer.run( l );
	        plf.write( data );
	        if (done != null) {
	            defer( done );
	        }
	    }

	    if (session.name == null || saveAs) {
	        prompt('playlist name', null, function( title ) {
	            if (title == null) {
	                savePlaylist(saveAs, done);
	            }
                else {
                    //l.title = title;
                    session.name = title;
                    finish();
                }
	        });
	    }
        else {
            finish();
        }
	}

	/**
	  * load the saved playlist by the given name
	  */
	public function loadPlaylist(name:String, ?done:Void->Void):Void {
	    if (app.appDir.playlistExists( name )) {
	        var plf = app.appDir.playlistFile( name );
	        var reader = new pman.format.xspf.Reader();
	        var l:Playlist = reader.read(plf.read());
	        clearPlaylist();
	        var tmpShuffle = shuffle;
	        shuffle = false;
			session.name = name;

	        addItemList(l.toArray(), function() {
                shuffle = tmpShuffle;
                session.name = name;
                if (done != null) {
                    defer( done );
                }
	        });
	    }
        else {
            if (done != null) {
                defer( done );
            }
        }
	}

	/**
	  * save the current playlist to a file
	  */
	public function exportPlaylist(?done : Void->Void):Void {
	    function cb(path : Path) {
	        var supportedFormats:Array<String> = ['m3u', 'xspf'];
	        if (!supportedFormats.has(path.extension.toLowerCase())) {
	            path.extension = 'xspf';
	        }
            var file = new File( path );
            switch (path.extension.toLowerCase()) {
                case 'm3u':
                    var data = pman.format.m3u.Writer.run( session.playlist );
                    file.write( data );

                case 'xspf':
                    var data = pman.format.xspf.Writer.run( session.playlist );
                    file.write( data );

                default:
                    return ;
            }
            if (done != null) {
                done();
            }
	    }
	    app.fileSystemSavePrompt({
            title: 'Export Playlist',
            buttonLabel: 'Save',
            defaultPath: Std.string(App.getPath( Videos ).plusString( 'playlist.xspf' )),
            filters: [FileFilter.PLAYLIST],
            complete: cb
	    });
	}

	/**
	  * save the Session into a File
	  */
	public function saveState():Void {
	    if (session.playlist.length == 0) {
	        session.deleteSavedState();
	    }
        else {
            session.save();
        }
	}

	/**
	  * restore previously saved Session
	  */
	public function restoreState(?done : Void->Void):Void {
	    session.restore( done );
	}

	/**
	  * get the current player status
	  */
	public function getStatus():PlayerStatus {
	    return c.getStatus();
	}

	/**
	  * create a new ProgressBar for the given Task and attach it to the view
	  */
	public function showProgressBar(task:StandardTask<String, Dynamic>, ?bar:CanvasProgressBar):Void {
	    if (bar == null)
	        bar = new CanvasProgressBar(task, this);
	    view.addSibling( bar );
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
	public function snapshot(?done : VoidCb):Void {
		if (done == null) {
			done = (function(?error) {
				if (error != null)
					throw error;
			});
		}
	    if (!track.type.match(MTVideo)) {
	        return ;
	    }

	    var task = new SaveSnapshot(this, track, currentTime);
	    task.run(function(?error, ?snapshotPath:Path) {
	        if (error != null) {
	            done( error );
	        }
            else if (snapshotPath != null) {
                trace( snapshotPath );
            }
	    });
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
	  * add a bookmark to the current time
	  */
	public function addBookmark(?done:Void->Void):Void {
        var wasPlaying = getStatus().equals( Playing );
	    pause();
	    function complete() {
	        if ( wasPlaying ) {
	            play();
	        }
	        if (done != null) {
	            done();
	        }
	    }

        if (track != null) {
            prompt('bookmark name', null, function(name : String) {
                var mark = new Mark(Named( name ), currentTime);
                track.addMark(mark, function() {
                    complete();
                });
            });
        }
        else complete();
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
	  * create route to the current media on the http server
	  */
	public function httpRouteTo(?t : Track):Null<String> {
	    if (t == null) {
	        if (track == null)
	            return null;
            else
                t = track;
        }
        var path = t.getFsPath();
        if (path == null)
            return null;
        else {
            return app.httpServe( path );
        }
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
	    items = items.filter.fn(_.isRealFile());
	    function complete():Void {
	        defer(function() {
	            if (done != null) {
	                done();
	            }
	            var dl = new TrackListDataLoader();
	            dl.load(items, function(?error, ?result) {
	                null;
	            });
	        });
	    }

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
                        complete();
                    }
                });
            }
            else {
                complete();
            }
        });
	}

	/**
	  * clear the playlist
	  */
	public function clearPlaylist():Void {
		session.playlist.clear();
		session.name = null;
		if (session.hasMedia()) {
			session.blur();
		}
	}

	/**
	  * shuffle the playlist
	  */
	public function shufflePlaylist():Void {
        var pl = session.playlist.toArray();
        clearPlaylist();
        var r = new Random();
        r.ishuffle( pl );
        addItemList( pl );
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
			/*
			message({
                text: newTrack.title,
                fontSize: '10pt'
			});
			*/

			// update the database regarding the Track that has just come into focus
			var ms = app.db.mediaStore;
			newTrack.editData(function( data ) {
			    // increment the 'views'
			    data.views++;

                // get previous playback progress (if available)
                var lastTime:Null<Float> = data.getLastTime();

                // if playback progress was retrieved
                if (lastTime != null) {
                    defer(function() {
                        // seek to it
                        currentTime = lastTime;

                        // fire the TrackReady event
                        session.trackReady.call( newTrack );
                    });
                }
			});
		}

		// automatically save the playback settings
		app.appDir.savePlaybackSettings( this );

		// notify all components
		components.iter.fn(_.onTrackChanged(delta));
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
            var isended:Bool = ended;
            var time:Float = currentTime;
            track.editData(function( data ) {
                if ( isended ) {
                    //data.marks = data.marks.filter.fn(!_.type.equals( LastTime ));
                    data.removeLastTimeMark();
                }
                else if (time > 0.0) {
                    data.addMark(new Mark(LastTime, time));
                }
            });
		}

		// notify all components
		components.iter.fn(_.onTrackChanging(delta));
	}

	/**
	  * current Track has been 'prepared' and is fully ready for playback
	  */
	private function _onTrackReady(t : Track):Void {
	    dispatch('track-ready', t);
	    components.iter.fn(_.onTrackReady( t ));
	}

	/**
	  * build [this] context Menu
	  */
	public function buildMenu(callback : MenuTemplate->Void):Void {
	    defer(function() {
	        var stack = new AsyncStack();
	        var menu:MenuTemplate = new MenuTemplate();

	        stack.push(function(next) {
	            menu.push({
                    label: 'Next',
                    click: function(i,w,e) gotoNext()
	            });
	            menu.push({
                    label: 'Previous',
                    click: function(i,w,e) gotoPrevious()
	            });
	            next();
	        });

	        stack.push(function(next) {
	            menu.push({
                    label: 'Playlist',
                    submenu: [
                    {
                        label: 'Clear',
                        click: function(i,w,e) clearPlaylist()
                    },
                    {
                        label: 'Shuffle',
                        click: function(i,w,e) shufflePlaylist()
                    }
                    ]
	            });
	            next();
	        });

	        stack.push(function(next) {
	            if (track != null) {
	                track.buildMenu(function( trackItem ) {
	                    trackItem = trackItem.slice( 2 );
	                    menu.push({
                            label: 'Track',
                            submenu: trackItem
	                    });
	                    next();
	                });
	            }
                else next();
	        });

	        stack.run(function() {
	            callback( menu );
	        });
	    });
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
	
	/**
	  * goto the previous track, or the beginning of the Track
	  */
	public function gotoPrevious(?cb : OpenCbOpts):Void {
	    if (currentTime >= 5.0) {
	        currentTime = 0.0;
	    }
        else {
            gotoByOffset(-1, cb);
        }
	}
	
	/**
	  * start current track over, erasing previous playback progress if present
	  */
	public function startOver(?cb : Void->Void):Void {
	    inline function done() {
	        if (cb != null)
	            defer( cb );
	    }

	    if (track == null) {
	        done();
	    }
        else {
            function erase(i : TrackData) {
                i.removeLastTimeMark();
            }
            track.editData(erase, function() {
                currentTime = 0.0;
                done();
            });
        }
	}

	/**
	  * override [this] Player's dispatch method
	  */
	override function dispatch<T>(name:String, data:T):Void {
	    super.dispatch(name, data);

	    var now:Date = Date.now();
	    eventTimes[name] = now;
	}

	/**
	  * get most recent recent occurrence time (if any) for the given event
	  */
	public inline function getMostRecentOccurrenceTime(event : String):Maybe<Date> {
	    return eventTimes[event];
	}

/* === Computed Instance Fields === */

	public var duration(get, never):Duration;
	private inline function get_duration() return c.duration;

	public var durationTime(get, never):Float;
	private inline function get_durationTime() return c.durationTime;

	public var paused(get, never):Bool;
	private inline function get_paused() return c.paused;

	public var currentTime(get, set):Float;
	private inline function get_currentTime() return c.currentTime;
	private inline function set_currentTime(v) return (c.currentTime = v);

	public var volume(get, set):Float;
	private inline function get_volume():Float return c.volume;
	private inline function set_volume(v : Float):Float return (c.volume = v);

	public var playbackRate(get, set):Float;
	private inline function get_playbackRate():Float return c.playbackRate;
	private inline function set_playbackRate(v : Float):Float return (c.playbackRate = v);

	public var shuffle(get, set):Bool;
	private inline function get_shuffle():Bool return c.shuffle;
	private inline function set_shuffle(v : Bool):Bool return (c.shuffle = v);

	public var muted(get, set):Bool;
	private inline function get_muted() return c.muted;
	private inline function set_muted(v) return (c.muted = v);

	public var repeat(get, set):RepeatType;
	private inline function get_repeat() return c.repeat;
	private inline function set_repeat(v) return (c.repeat = v);

	public var ended(get, never):Bool;
	private inline function get_ended() return c.ended;

	public var track(get, never):Null<Track>;
	private inline function get_track():Null<Track> return session.focusedTrack;

	public var target(get, never):PlaybackTarget;
	private inline function get_target() return session.target;

	public var c(get, never):PlayerController;
	private inline function get_c() return controller;

/* === Instance Fields === */

	public var app : BPlayerMain;
	public var page : PlayerPage;
	public var theme : ColorScheme;
	public var view : PlayerView;
	public var session : PlayerSession;
	public var isReady(default, null): Bool;
	public var components : Array<PlayerComponent>;
	public var controller : PlayerController;

	private var readyEvent : VoidSignal;
	private var eventTimes : Dict<String, Date> = {new Dict();};
}

typedef OpenCbOpts = {
	@:optional function manipulate(mc : MediaController):Void;
	@:optional function ready():Void;
	@:optional function attached():Void;

	@:optional var startTime : Float;
};
