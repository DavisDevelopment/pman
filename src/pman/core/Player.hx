package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.http.*;
import tannus.geom2.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.Random;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

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
import pman.display.*;
import pman.display.media.*;
import pman.media.*;
import pman.media.info.*;
import pman.bg.media.Mark;
import pman.bg.media.RepeatType;
import pman.ui.*;
import pman.ui.views.curses.models.*;
import pman.ui.views.curses.*;
import pman.ui.PlayerMessageBoard;
import pman.db.PManDatabase;
import pman.ds.*;
import pman.async.*;
import pman.async.tasks.*;
import pman.pmbash.Interp as PMBashInterp;

//== [TESTING IMPORTS]
import pman.sys.FSWFilter;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using DateTools;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.RandomTools;
using pman.core.ExecutorTools;
using pman.media.MediaTools;
using pman.bg.URITools;
using pman.core.PlayerTools;
using pman.async.Asyncs;
using tannus.FunctionTools;
using tannus.math.TMath;

class Player extends EventDispatcher {
	/* Constructor Function */
	public function new(main:BPlayerMain, page:PlayerPage):Void {
	    super();

		app = main;
		this.page = page;

        // [this] Player's ready-state
		_rs = new OnceSignal();

		// [this] Player's controller
		controller = new PlayerController( this );

		// the app's color scheme
		theme = new ColorScheme();

		// create the Player's view
		view = new PlayerView( this );

		// create the Player's view options
		viewOptions = new PlayerViewOptions();

		// create the Player's Session
		session = new PlayerSession( this );

		// [this] Player's list of components
		components = new Array();

        // Player flags
		flags = new Dict();
		conf = new PlayerInterfaceConfiguration( this );

        // pmbash interpreter
		pmbashInterp = new PMBashInterp();

		// create the media resolution context
		mediaResolutionContext = new MediaResolutionContext( this );

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
	    var startup = new PlayerStartup( this );
	    startup.run(function(?error : Dynamic) {
	        if (error != null) {
	            throw error;
            }
            else {
                #if (debug || !release)
                    //_test_tty(stage);
                    //_test_curses( stage );
                #end
            }
	    });
	}

	/**
	  * test the 'curses' shit
	  */
	private function _test_curses(stage: Stage):Void {
	    /* prepare grid */
	    var grid = new CellGrid(100, 100);
	    grid.fontFamily = 'SourceCodePro';
	    grid.fontSize = 10;
	    grid.fontSizeUnit = 'px';
	    grid.fg = '#1ADD1A';
	    grid.bg = '#2F2B2B';

        /* create grid view */
	    var gridView = new CellGridView( grid );

        /* attach view to stage */
	    function attachGridView() {
	        stage.addChild( gridView );
	    }

	    window.expose('grid', grid);
	    window.expose('gridView', gridView);
	    window.expose('renderGrid', attachGridView);
	}

    /**
      * test the character matrix class
      */
	private function _test_tty(stage: Stage):Void {
	    // create the character-matrix view
	    var matrix = new pman.ui.views.CharacterMatrixView({
            width: 200,
            height: 200,
            fontFamily: 'SourceCodePro',
            fontSize: 10,
            fontSizeUnit: 'px',
            foregroundColor: '#1ADD1A',
            backgroundColor: '#2F2B2B',
            autoBuild: false
	    });
		//matrix.calculateSize(view.mediaRect.floor());
		matrix.calculateSize( stage.rect );
	    matrix.init();

        // expose the matrix into the global scope
	    window.expose('matrix', matrix);
	    window.expose('mc', matrix.cursor);
        echo( matrix );

        // get a reference to the cursor
        var c = matrix.cursor;
        c.write('| Betty, get my urinal.');
        c.nextLine();
        c.write('| I really need, boo');
        c.nextLine();
        c.write('| I hope you get it soon');
        c.nextLine();

        c.etch(function(c) {
            var boldred ={
                fg: new Color(255, 0, 0),
                bold: true
            };

            //c.etch(fn(_.write('[== ')), boldred)
            c.write('[== ', null, null, boldred);
            c.write('this should now be the last line of text');
            c.write(' ==]', null, null, boldred);
        });

        c.nextLine();
        c.clearLine(null, null, null, '=');

        /**
          * test rapid manipulation of the matrix in real time
          */
        function realTimeTests() {
            //
        }
        window.expose('matrixRealTimeTest', realTimeTests);

        function attachR() {
            var ttyr = new pman.ui.views.CharacterMatrixViewRenderer( matrix );
            matrix.attachRenderer( ttyr );
            view.addSibling( ttyr );
        }
        window.expose('renderMatrix', attachR);
        //wait(5000, attachR);
	}

	/**
	  * a frame has passed
	  */
	public function tick():Void {
	    dispatch('tick', null);
	    controller.tick();

	    var time:Float = now();
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
		box.readLine(function(text : Null<String>) {
		    if (text == null) {
		        return callback( null );
		    }
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
	  parse the given Launch Info
	 **/
	public function parseLaunchInfo(info: LaunchInfo):Void {
	    //TODO
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
	  * open the Preferences editor
	  */
	public function editPreferences():Void {
	    if (app.body.currentPage == page) {
	        var pp = new PreferencesPage( app );
	        app.body.open( pp );
	    }
	}

	/**
	  * handle the closing of the Player page
	  */
	public function close():Void {
	    dispatch('close', null);
	    pause();
	    if (track != null && track.renderer != null) {
	        track.renderer.onClose( this );
	    }
	}

	/**
	  * handle the player page reopening
	  */
	public function reopen():Void {
	    dispatch('reopen', null);
	    if (track != null && track.renderer != null) {
	        track.renderer.onReopen( this );
	    }
	}

	/**
	  * save current playlist to the filesystem
	  */
	public function savePlaylist(saveAs:Bool=false, ?name:String, ?format:String, ?done:Void->Void):Void {
        var l:Playlist = session.playlist;

        if (name != null) {
            session.name = name;
        }

        var data:Playlist->ByteArray;
        if (format != null) {
            switch (format.toLowerCase().trim()) {
                case 'm3u':
                    data = (l -> pman.format.m3u.Writer.run( l ));

                case 'csv':
                    data = (function(list: Playlist) {
                        var labels:Array<String> = ['id', 'title', 'duration', 'uri'];
                        var rows:Array<Array<String>> = [];
                        var encode = (rows -> tannus.csv.Dsv.encode(rows, {delimiter:','}));
                        for (t in list) {
                            rows.push([
                                t.mediaId.ifEmpty(''),
                                t.title,
                                (if (t.data != null && t.data.meta != null)
                                    (''+t.data.meta.duration)
                                else
                                    'null'
                                ),
                                t.uri
                            ]);
                        }
                        rows.unshift( labels );
                        return ByteArray.ofString(encode( rows ));
                    });

                case 'xspf', 'xml', _:
                    data = (l -> pman.format.xspf.Writer.run(pman.format.xspf.Tools.toXspfData( l )));
            }
        }
        else {
            data = (l -> pman.format.xspf.Writer.run(pman.format.xspf.Tools.toXspfData( l )));
        }

	    function finish():Void {
	        var plf = app.appDir.playlistFile( session.name );
	        var fdata:ByteArray = data( l );
	        plf.write( fdata );
	        if (done != null) {
	            defer( done );
	        }
	    }

	    if (session.name == null || saveAs) {
	        prompt('playlist name', null, function( title ) {
	            if (title == null) {
	                savePlaylist(saveAs, "New Playlist", null, done);
	            }
                else {
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
	        var data = reader.read(plf.read());
	        echo( data );
	        var trackList:Array<Track> = data.tracks.reduce(function(l:Array<Track>, node) {
	            var loc = (node.locations[0] + '').toUri();
	            if (loc.isUri()) {
	                var src = loc.toMediaSource();
	                var provider = src.toMediaProvider();
	                l.push(new Track( provider ));
	            }
	            return l;
	        }, new Array());

	        clearPlaylist();
	        var tmpShuffle = shuffle;
	        shuffle = false;
			session.name = name;

	        addItemList(trackList, function() {
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
	public function exportPlaylist(?done:Void->Void):Void {
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
                    var data = pman.format.xspf.Writer.run(pman.format.xspf.Tools.toXspfData( session.playlist ));
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
	@:deprecated('betty')
	public function saveState(?location:Path):Void {
	    // if configured to save session data even when the session data is empty
	    if (appState.sessMan.saveEmptySession && !session.hasContent()) {
	        // then, as there's nothing to save when the queue is completely empty, just delete the file
	        session.deleteSavedState();
	    }
        else {
            session.save({
                location: location
            });
        }
	}

	/**
	  * save the Session, automatically
	  */
	public inline function saveStateAuto():Void {
	    if ( appState.sessMan.autoSaveSession ) {
	        saveState();
	    }
	}

	/**
	  * restore previously saved Session
	  */
	public function restoreState(?name:String, ?dir:String, ?done:VoidCb):Void {
	    session.restore(name, dir, done);
	}

	/**
	  * get the current player status
	  */
	public function getStatus():PlayerStatus {
	    return c.getStatus();
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
		    // who/what triggered [this] load
            trigger: 'user',

            // when [track] is attached to [this]
			attached: function() {
			    // invoke callback if provided
				if (cb.attached != null) {
					cb.attached();
				}
			},

			// when manipulation of [track] is possible
			manipulate: function(mc : MediaController) {
			    // if [track] can be seeked and is not audio media
			    if (track.hasFeature( Seek ) && !track.type.equals(MTAudio)) {
			        // if a start time was provided
                    if (cb.startTime != null) {
                        // seek to that start time
                        mc.setCurrentTime( cb.startTime );
                    }
                }

                // invoke callback if provided
                if (cb.manipulate != null) {
                    cb.manipulate( mc );
                }
			},

			// when the media is completely ready to play
			ready: function() {
			    // if [track] has playback feature
			    if (track.hasFeature( Playback )) {
			        // and if we were playing before beginning to switch tracks
                    if ( playing ) {
                        // then play
                        play();
                    }
                }

                // invoke callback if provided
				if (cb.ready != null) {
					cb.ready();
				}
			}
		});
	}

    /**
      * open some Media
      */
	public inline function openMedia(provider:MediaProvider, ?cb:OpenCbOpts):Void {
		openTrack(new Track( provider ), cb);
	}

/* === System Methods === */

	/**
	  * wait until Player is ready
	  */
	public inline function onReady(callback : Void->Void):Void {
	    _rs.await( callback );
	}

	/**
	  * add the Media referred to by the given paths to the Session
	  */
	public inline function addPathsToSession(paths : Array<String>):Void {
	    addItemList(paths.map(s->s.toTrack()));
	}

	/**
	  * capture snapshot of media
	  */
	public function snapshot(?size:String, ?done:VoidCb):Void {
	    done = done.nn().toss();

		// return out if media isn't video
	    if (!track.type.match(MTVideo)) {
	        return done();
	    }

        // get the Track's bundle
	    var bundle = track.getBundle();

	    // get the snapshot itself
	    var snapp = bundle.getSnapshot(currentTime, nullOr(size, '30%'));

	    // when [snapp] has completed
        snapp.then(function(item) {
            // if snapshot should be shown
            if ( appState.player.showSnapshot ) {
                // create a snapshot view
                var vu = new SnapshotView(this, item.getPath());

                // add it to the stage
                view.addSibling( vu );
            }
        });

        // if [snapp] fails
        snapp.unless(function(error) {
            done( error );
        });
	}

	/**
	  * add a bookmark to the current time
	  */
	public function addBookmark(?done:VoidCb):Void {
	    // check whether we're currently playing
        var wasPlaying:Bool = getStatus().equals( Playing );

        // pause [this]
	    pause();

	    // create a callback
	    function complete(?error: Dynamic):Void {
	        // if we were playing
	        if ( wasPlaying ) {
	            // initiate playback
	            play();
	        }

	        // if a callback was provided
	        if (done != null) {
	            // invoke it
	            done( error );
	        }
	    }

        // if [track] isn't null
        if (track != null) {
            // create a new BookmarkPrompt object
            var box:BookmarkPrompt = new BookmarkPrompt();

            // 'read' a Mark object from [box]
            box.readMark(function(mark: Null<Mark>):Void {
                // if [mark] exists
                if (mark != null) {
                    // add [mark] to [track], and when that's done
                    track.addMark(mark, function(?error) {
                        // if there was an error
                        if (error != null) {
                            // forward that to [complete]
                            complete( error );
                        }
                        // otherwise
                        else {
                            // capture a snapshot at [mark.time]
                            snapshot(function(?err) {
                                complete( err );
                            });
                        }
                    });
                }
            });
        }
        else {
			return complete();
        }
	}

	/**
	  * prompt the user to select media files
	  */
	public function selectFiles(callback : Array<File> -> Void):Void {
		// middle-man callback to map the paths to File objects
		function _callback(?error, ?paths:Array<Path>):Void {
			// ... why did I do this?
			//callback(paths.filter( Fs.exists ).map.fn([path] => new File(new Path( path ))));
			callback(paths.map.fn([path] => new File(path)));
		}
		dialogs.selectFiles({
			title: 'Select one or more files to open',
			buttonLabel: 'Open That Shit',
			filters: [
			    FileFilter.ALL,
			    FileFilter.VIDEO,
			    FileFilter.AUDIO,
			    FileFilter.IMAGE,
			    FileFilter.PLAYLIST
			]
		}, _callback);
	}

	/**
	  * prompt the user to select a directory
	  */
	public function selectDirectory(callback : Array<Directory> -> Void):Void {
		function _callback(?error, ?paths:Array<Path>):Void {
			var dirs = [];
			for (path in paths) {
				if (Fs.exists( path ) && Fs.isDirectory( path )) {
					dirs.push(new Directory( path ));
				}
			}
			callback( dirs );
		}
	    dialogs.open({
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
			var url:Url = Url.fromString( text );
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
	    items = items.filter(function(item) {
			//echo( item.source );
	        return item.isRealFile();
	    });
		//echo( items );
	    var start = now();
	    var plv = this.getPlaylistView();
	    if (plv != null) { plv.lock(); }

	    function completeEfficient():Void {
            if (plv != null) plv.unlock();
            if (done != null) done();

            var edl = new EfficientTrackListDataLoader(items, app.db.mediaStore);
            edl.run(function(?error) {
                if (error != null) {
                    //report( error );
                    #if debug 
                    throw error; 
                    #else 
                    report( error ); 
                    #end
                }
                else {
                    #if debug
                    trace('took ${now() - start}ms for Player.addItemList(Track[${items.length}]) to complete');
                    #end
                    dispatch('track[]dataloaded', {
                        time: (now() - start),
                        items: items,
                        data: items.map.fn(_.data)
                    });
                }
            });
	    }

	    // initialize these items
	    var initStart = now();
	    var begin = (() -> items.initAll(function() {
	        trace('took ${now() - initStart}ms to "initialize" ${items.length} tracks');
	        initStart = now();
            // if these are the first items added to the queue, autoLoad will be invoked once they are all added
            var autoLoad:Bool = session.playlist.empty();
            var willPlay:Null<Track> = null;
            if ( autoLoad ) {
                willPlay = items[0];
            }

            // shuffle the tracks
            if ( session.pp.shuffle ) {
                var rand = new Random();
                items = rand.shuffle( items ).compact();
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
                        trace('took ${now() - initStart} to append ${items.length} tracks to queue');
                        completeEfficient();
                    }
                });
            }
            else {
                trace('took ${now() - initStart} to append ${items.length} tracks to queue');
                completeEfficient();
            }
        }));
        
        /**
          kick off the initialization of the item-list
         **/
        session.kickOff(function(?error) {
            if (error != null)
                throw error;
            else {
                begin();
            }
        });
	}

	/**
	  * clear the playlist
	  */
	public function clearPlaylist():Void {
		if (session.hasMedia()) {
			session.blur();
		}
		var tab = session.activeTab;
		if (tab == null) {
		    return ;
		}
        else {
            tab.focusedTrack = null;
            tab.blurredTrack = null;
            tab.playlist.clear();
            session.name = null;
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
		return session.playlist[index];
	}

	/**
	  * get the media item by offset from current media item
	  */
	public inline function getTrackByOffset(offset : Int):Null<Track> {
        return getTrack(session.indexOfCurrentMedia() + offset);
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
			function dostuff() {
                newTrack.editData(function(data, done) {
                    // increment the 'views'
                    if (getStatus().match( Playing )) {
                        data.views++;
                        done = done.wrap(function(f, ?error) {
                            defer( newTrack.updateView );
                            f( error );
                        });
                    }

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

                    // declare complete
                    done();
                });
			}

			dostuff();

			if (!getStatus().match( Playing )) {
			    once('play', untyped function() {
			        if (track == newTrack) {
			            function iv() {
                            newTrack.editData(function(data, done) {
                                data.views++;
                                //defer(newTrack.updateView.join(done.void()));
                                defer(function() {
                                    newTrack.updateView();
                                    done();
                                });
                            });
                        }

                        iv();
			        }
			    });
			}

			//defer(function() {
				//view.stage.calculateGeometry();
			//});
		}

		// automatically save the playback settings
		session.savePlaybackSettings();

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
            track.editData(function(data, done) {
                if ( isended ) {
                    data.removeLastTimeMark();
                }
                else if (time > 0.0) {
                    data.addMark(new Mark(LastTime, time));
                }
                done();
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
	  *
	  */

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
		c.play();
	}
	
	/**
	  * pause playback of media
	  */
	public function pause():Void {
		c.pause();
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
		c.togglePlayback();
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
            function erase(i:TrackData, next) {
                i.removeLastTimeMark();
                next();
            }
            track.editData(untyped erase, function(?error) {
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

	/**
	  * execute a String of pmbash code
	  */
	public function exec(code:String, done:VoidCb):Void {
	    pmbashInterp.executeString(code, done);
	}

	/**
	  * open a pmbash terminal
	  */
	public function terminal(?complete:VoidCb, ?code:String):Void {
	    if (complete == null) {
	        complete = (function(?e) null);
	    }
	    if (code == null) {
	        code = '';
	    }

	    var term = new PMBashTerminal( this );
	    term.readExpr(function(?error:Dynamic, ?expr) {
	        if (error != null) {
	            complete( error );
	        }
            else if (expr != null) {
                pmbashInterp.execute(expr, complete);
            }
	    });
	    term.open();
	    defer(function() {
	        term.focus();
	    });
	}

    /**
      * get or set the value of a flag
      */
	public function flag<T>(key:String, ?value:T):Null<T> {
	    if (value == js.Lib.undefined) {
	        return flags[key];
	    }
        else {
            return (flags[key] = value);
        }
	}

	/**
	  * verify existence of a flag
	  */
	public function hasFlag(flag : String):Bool {
	    return flags.exists( flag );
	}

    /**
      * delete a flag
      */
	public function removeFlag(flag : String):Bool {
	    return flags.remove( flag );
	}

	/**
	  * add a flag
	  */
	public inline function addFlag(flag : String):Void {
	    this.flag(flag, true);
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

	public var scale(get, set):Float;
	private inline function get_scale() return c.scale;
	private inline function set_scale(v) return (c.scale = v);

	public var ended(get, never):Bool;
	private inline function get_ended() return c.ended;

	public var track(get, never):Null<Track>;
	private inline function get_track():Null<Track> return session.focusedTrack;

	public var target(get, never):PlaybackTarget;
	private inline function get_target() return session.target;

	public var c(get, never):PlayerController;
	private inline function get_c() return controller;

	public var isReady(get, never): Bool;
	private inline function get_isReady() return _rs.v;

/* === Instance Fields === */

    // the app's main class
	public var app : BPlayerMain;

	// the page on which [this] Player is displayed
	public var page : PlayerPage;

	// the current color palette
	public var theme : ColorScheme;

	// the view used for displaying the player
	public var view : PlayerView;

	// player-view options
	public var viewOptions : PlayerViewOptions;

	// the current session
	public var session : PlayerSession;

	// player-components that have been attached
	public var components : Array<PlayerComponent>;

	// 'controller' used for low-level nitty-gritty playback-stuff
	public var controller : PlayerController;

	// dynamic-value player-flags
	public var flags : Dict<String, Dynamic>;

	// user interface configuration stuff
	public var conf: PlayerInterfaceConfiguration;

    // interpreter for PMBash language
	public var pmbashInterp : PMBashInterp;

	// the media-resolution context
	public var mediaResolutionContext : MediaResolutionContext;

	// ready signal
	private var _rs : OnceSignal;

	// Datetimes for all events
	private var eventTimes : Dict<String, Date> = {new Dict();};
}

typedef OpenCbOpts = {
	@:optional function manipulate(mc : MediaController):Void;
	@:optional function ready():Void;
	@:optional function attached():Void;

	@:optional var startTime : Float;
};
