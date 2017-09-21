package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry.FSEntryType;
import tannus.sys.FileSystem as Fs;
import tannus.http.Url;
import tannus.geom.Rectangle;

import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.media.MediaType;
import pman.ui.pl.TrackView;
import pman.media.info.Mark;
import pman.media.info.*;
import pman.async.*;
import pman.async.tasks.*;

import haxe.Serializer;
import haxe.Unserializer;

import electron.*;
import electron.Shell;
import electron.Tools.defer;
import Slambda.fn;
import tannus.math.TMath.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.ds.SortingTools;
using tannus.math.TMath;

using pman.async.VoidAsyncs;

/**
  * pman.media.Track -- object that centralizes media playback state
  */
class Track extends EventDispatcher implements IComparable<Track> {
	/* Constructor Function */
	public function new(p:MediaProvider):Void {
	    super();

		provider = p;

		media = null;
		driver = null;
		renderer = null;

		_dataLoaded = new Signal();

		__checkEvents = false;
	}

/* === Instance Methods === */

    /**
      * initialize [this] Track
      */
    public function init(?done : Void->Void):Void {
        if (done == null) {
            done = (function() null);
        }

        if ( ready ) {
            defer( done );
        }
        else {
            defer(function() {
                _ready = true;
                done();
            });
        }
    }

	/**
	  * get the name of [this] Track
	  */
	public inline function getName():String return provider.getName();
	public inline function getURI():String return provider.getURI();

	/**
	  * nullify the m,d,r fields
	  */
	public inline function nullify():Void {
		media = null;
		driver = null;
		renderer = null;
	}

	/**
	  * deallocate the m,d,r fields
	  */
	public function deallocate():Void {
		if (media != null)
			media.dispose();
		if (driver != null)
			driver.dispose();
		if (renderer != null)
			renderer.dispose();
	}

	/**
	  * load the mediaContext data onto [this] Track
	  */
	public function mount(callback : Null<Dynamic> -> Void):Void {
		this.loadTrackMediaState(function(error : Null<Dynamic>):Void {
			if (error != null) {
				deallocate();
				nullify();
			}
            else {
                var ps = driver.getPlaySignal();
                ps.on(function() player.dispatch('play', null));
            }
			callback( error );
		});
	}

	/**
	  * the inverse effect of 'mount'
	  */
	public inline function dismount():Void {
		deallocate();
		nullify();
	}

	/**
	  * check whether [this] Track is mounted
	  */
	public inline function isMounted():Bool {
		return (media != null && driver != null && renderer != null);
	}

	/**
	  * Serialize [this] Track
	  */
	@:keep
	public function hxSerialize(s : Serializer):Void {
		inline function w(x) s.serialize( x );

		w( provider );
	}

	/**
	  * Unserialize a Track
	  */
	@:keep
	public function hxUnserialize(u : Unserializer):Void {
		provider = u.unserialize();
	}

	/**
	  * create a clone of [this]
	  */
	public function clone(deep:Bool = false):Track {
	    var copy = new Track( provider );
	    copy.data = data;
	    return copy;
	}

    /**
      * check for equality
      */
    public inline function equals(other : Track):Bool {
        return (compareTo( other ) == 0);
    }

    /**
      * perform 'icompare' operation between [this] and [other]
      */
    public function compareTo(other : Track):Int {
        return (source.compareEnumValues( other.source ));
    }

    /**
      * obtain a reference to the media_item row attached to [this] Track in the database
      */
    public function getDbMediaItem(db:PManDatabase, callback:MediaItem->Void):Void {
        var mip = db.mediaStore.cogMediaItem( uri );
        mip.then( callback ).unless(function(error : Dynamic) {
            throw error;
        });
    }

    /**
      * obtain a reference to the MediaInfo object associated with [this] Track in the database
      */
    public function getDbMediaInfo(db:PManDatabase, callback:DbMediaInfo->Void):Void {
        getDbMediaItem(db, function(item) {
            item.getInfo( callback );
        });
    }

    /**
      * load the TrackData for [this] Track
      */
    public function getData(done : Cb<TrackData>):Void {
        if (data == null) {
            if ( !_loadingData ) {
                var loader = new LoadTrackData(this, BPlayerMain.instance.db);
                loader.run(function(?error, ?td) {
                    if (error != null) {
                        throw error;
                        done( error );
                    }
                    else {
                        if (td != null) {
                            this.data = td;
                            var tv = getView();
                            if (tv != null) {
                                tv.update();
                            }
                        }
                        else {
                            throw 'Error: Loaded TrackData is null';
                        }

                        done(null, td);
                    }
                });
            }
            else {
                _dataLoaded.once(function( data ) {
                    _loadingData = false;
                    done(null, data);
                });
            }
        }
        else {
            defer(function() {
                done(null, data);
            });
        }
    }

    /**
      * get the TrackView associated with [this] Track
      */
    public function getView():Null<TrackView> {
        var p = BPlayerMain.instance.playerPage;
        if (p.playlistView != null) {
            return p.playlistView.viewFor( this );
        }
        else return null;
    }

    /**
      * build the menu for [this] Track
      */
    public function buildMenu(callback : MenuTemplate -> Void):Void {
        getData(function(?error, ?data) {
            var mt:MenuTemplate = new MenuTemplate();

            mt.push({
                label: 'Play',
                click: function(i,w,e) player.openTrack( this )
            });

            // place this track immediately after the currently-playing track
            mt.push({
                label: 'Play Next',
                click: function(i,w,e) {
                    playlist.ascend.fn(l=>l.move(this, fn(l.getRootPlaylist().indexOf(player.track)+1)));
                }
            });
            mt.push({
                label: (data != null && data.starred ? 'Unfavorite' : 'Favorite'),
                click: function(i,w,e) {
                    toggleStarred();
                }
            });

            mt.push({type: 'separator'});

            // remove track from current session playlist (queue)
            mt.push({
                label: 'Remove From Queue',
                click: function(i,w,e) {
                    playlist.ascend.fn(_.remove(this, _.isRootPlaylist()));
                }
            });

            // remove all tracks before [this] one from the queue
            mt.push({
                label: 'Remove All Previous Tracks From Queue',
                click: function(i,w,e) {
                    // get all tracks that are above [this] one in the list
                    var affected = playlist.getRootPlaylist().before( this );
                    if (affected.empty())
                        return ;
                    // pop off the last item in that list
                    var last = affected.pop();
                    // iterate over the rest
                    for (t in affected) {
                        // walking up the playlist hierarchy, removing each track and each layer of that hierarchy
                        // never broadcasting a 'change' signal
                        playlist.ascend.fn(_.remove(t, false));
                    }
                    // do the same to the last item, and broadcast the 'change' event
                    // when the last track is removed from the root playlist
                    playlist.ascend.fn(_.remove(last, _.isRootPlaylist()));
                }
            });

            // remove all tracks after [this] one from the queue
            mt.push({
                label: 'Remove All Following Tracks From Queue',
                click: function(i,w,e) {
                    // get all tracks that are above [this] one in the list
                    var affected = playlist.getRootPlaylist().after( this );
                    if (affected.empty())
                        return ;
                    // pop off the last item in that list
                    var last = affected.pop();
                    // iterate over the rest
                    for (t in affected) {
                        // walking up the playlist hierarchy, removing each track and each layer of that hierarchy
                        // never broadcasting a 'change' signal
                        playlist.ascend.fn(_.remove(t, false));
                    }
                    // do the same to the last item, and broadcast the 'change' event
                    // when the last track is removed from the root playlist
                    playlist.ascend.fn(_.remove(last, _.isRootPlaylist()));
                }
            });

            // open [this] Track in a new Tab
            mt.push({
                label: 'Open in New Tab',
                click: function(i, w, e) {
                    function doit():Void {
                        //playlist.remove( this );
                        var tabIndex = session.newTab(function(tab) {
                            tab.playlist.push( this );
                            tab.blurredTrack = this;
                        });
                        //session.setTab( tabIndex );
                    }
                    doit();
                }
            });

            (function() {
                // utility function for adding a single track (this one) to a saved playlist
                function add2(n : String) {
                    main.appDir.playlists.editSavedPlaylist(n, function(sl : Playlist) {
                        sl.push(this);
                    });
                }
                var spli:MenuTemplate = [];
                for (name in main.appDir.allSavedPlaylistNames()) {
                    spli.push({
                        label: name,
                        click: function(i,w,e) add2(name)
                    });
                }
                if (spli.length > 0)
                    spli.push({type: 'separator'});
                spli.push({
                    label: 'New Playlist',
                    click: function(i,w,e) {
                        player.prompt('new playlist title', 'My Playlist Title', null, function(line) {
                            if (line == null || line.empty())
                                return;
                            else add2( line );
                        });
                    }
                });
                mt.push({
                    label: 'Add to Playlist',
                    submenu: spli
                });
            }());

            mt.push({type: 'separator'});

            if (source.match(MSLocalPath(_))) {
                var path = getFsPath();
                mt.push({
                    label: 'Show in Folder',
                    click: function(i,w,e) {
                        Shell.showItemInFolder( path );
                    }
                });
                mt.push({
                    label: 'Rename',
                    click: function(i,w,e) {
                        _rename(function() {
                            trace('Track renamed');
                        });
                    }
                });
                mt.push({
                    label: 'Move to Trash',
                    click: function(i,w,e) {
                        _delete(function() {
                            trace('Track deleted');
                        });
                    }
                });
            }

            mt.push({type: 'separator'});

            var marks:MenuTemplate = new MenuTemplate();
            marks.push({
                label: 'Add Bookmark',
                click: function(i,w,e) {
                    player.addBookmark();
                }
            });
            marks.push({type: 'separator'});

            // bookmarks
            for (mark in data.marks) {
                switch ( mark.type ) {
                    case MarkType.Named( name ):
                        var time = mark.time;
                        marks.push({
                            label: name,
                            click: function(i,w,e) {
                                if (player.track != this) {
                                    player.openTrack(this, {
                                        startTime: time
                                    });
                                }
                                else {
                                    player.currentTime = time;
                                }
                            }
                        });

                    default:
                        continue;
                }
            }

            mt.push({
                label: 'Bookmarks',
                submenu: marks
            });

            callback( mt );
        });
    }

    /**
      * rename [this] Track
      */
    private function _rename(?done:Void->Void):Void {
        if (done == null)
            done = (function() null);

        var ren = new TrackRename(this, main.db.mediaStore);
        ren.run(function(?error:Dynamic) {
            if (error != null) {
                (untyped __js__('console.error'))(error);
            }
            else {
                if (ren.renamed != null) {
                    player.message('track renamed to "${ren.renamed.name}"');
                }
                else {
                    player.message('track was not renamed');
                }
            }
        });
    }

    /**
      * move [this] Track to Trash (delete it)
      */
    private function _delete(?done : Void->Void):Void {
        if (done == null)
            done = (function() null);

        var name = title;
        var tdel = new TrackDelete(this, main.db.mediaStore);
        tdel.run(function(?error : Dynamic) {
            if (error != null) {
                (untyped __js__('console.error'))(error);
            }
            else {
                if ( tdel.deleted )
                    player.message('moved "${name}" to Trash');
            }
        });
    }

/* === TrackData Methods === */

    /**
      * shorthand method to edit the TrackData for [this] Track
      */
    public function editData(action:TrackData->Void, ?complete:Void->Void):Void {
        getData(function(?error, ?data:TrackData) {
            if (data == null) {
                throw 'Error: TrackData is null';
            }
            action( data );
            data.save(function(?error) {
                if (error != null)
                    throw error;

                var v = getView();
                if (v != null) {
                    v.update();
                }
                if (complete != null) {
                    complete();
                }
            });
        });
    }

    /**
      * get the Path to [this]
      */
    public function getFsPath():Null<Path> {
        return switch ( source ) {
            case MediaSource.MSLocalPath(path): path;
            default: null;
        };
    }

    /**
      * check whether [this] Track references a real file
      */
    public function isRealFile():Bool {
        var path = getFsPath();
        if (path != null) {
            return FileSystem.exists( path );
        }
        else return true;
    }

    /**
      * set whether [this] Track is starred
      */
    public function setStarred(value:Bool, ?done:Void->Void):Void {
        editData(function(i) {
            i.starred = value;
        }, done);
    }

    public function toggleStarred(?done : Bool->Void):Void {
        var val:Bool = false;
        editData(function(i) {
            val = (i.starred = !i.starred);
        }, function() {
            if (done != null) {
                done( val );
            }
        });
    }

    public inline function star(?done : Void->Void):Void {
        setStarred(true, done);
    }

    public inline function unstar(?done : Void->Void):Void {
        setStarred(false, done);
    }

    public function addMark(mark:Mark, ?done:Void->Void):Void {
        editData(function(i) {
            i.addMark( mark );
        }, done);
    }

    /**
      * capture screenshot of given size, at given time
      */
    public function probe(time:Float, size:String, callback:Canvas->Void):Void {
        if (!type.equals( MTVideo ))
            return ;
        var thumbPath = player.app.appDir.appPath('_thumbs');
        var m = new ffmpeg.FFfmpeg(getFsPath().toString());
        var paths:Array<Path> = [];
        m.onFileNames(function(filenames) {
            paths = filenames.map.fn(thumbPath.plusString(_));
        }).onEnd(function() {
            var uri:String = ('file://${paths[0]}');
            Image.load(uri, function( img ) {
                img.ready.once(function() {
                    trace('IMAGE READY MOTHERFUCKER');
                    defer(function() {
                        var canvas = img.toCanvas();
                        @:privateAccess img.img.remove();
                        FileSystem.deleteFile( paths[0] );
                        callback( canvas );
                    });
                });
            });
        }).screenshots({
            folder: thumbPath.toString(),
            filename: '%s|%r|%f.png',
            size: size,
            timemarks: [time]
        });
    }

    /**
      * get all snapshots attached to [this] Track
      */
    public function getSnapshots():Dict<Float, Ref<Image>> {
        var ssd = new Directory(player.app.appDir.snapshotPath(), true);
        var gs = new GlobStar('${title}@<time>.png', 'i');
        var results:Dict<Float, Ref<Image>> = new Dict();
        for (entry in ssd.entries) {
            switch ( entry.type ) {
                case File( file ):
                    if (gs.test( file.path )) {
                        var data:Dynamic = gs.match( file.path );
                        if (data.time != null) {
                            var time:Float = Std.parseFloat( data.time );
                            results[time] = new Ref(new Getter(Image.load.bind('file://' + file.path)));
                        }
                    }

                default:
                    null;
            }
        }
        return results;
    }

    /**
      * get the Bundle for [this] Track
      */
    public function getBundle():Bundle {
        return Bundles.getBundle( this );
    }

    /**
      * 
      */
    public function getThumbs():Void {
        var b = getBundle();
        var count:Int = 6;
        var size = '35%';
        var thumbs = b.getThumbs(count, size);
        if (thumbs != null) {
            trace( thumbs );
        }
        else {
            // listen for when the described thumbnail set exists
            b.awaitThumbs(count, size, function(ts:Thumbs) {
                thumbs = ts;
                trace( thumbs );
            });

            // kick off the generation of those thumbnails
            b.genThumbs(count, size);
        }
    }

/* === Computed Instance Fields === */

	public var title(get, never):String;
	private inline function get_title():String return getName();

	public var uri(get, never):String;
	private inline function get_uri():String return getURI();
	
	public var type(get, never):MediaType;
	private inline function get_type():MediaType return provider.type;

	public var source(get, never):MediaSource;
	private inline function get_source():MediaSource return provider.src;

	public var ready(get, never):Bool;
	private inline function get_ready():Bool return _ready;

	public var main(get, never):BPlayerMain;
	private inline function get_main() return BPlayerMain.instance;

	public var player(get, never):Player;
	private inline function get_player() return main.player;

	public var session(get, never):PlayerSession;
	private inline function get_session() return player.session;

	public var playlist(get, never):Playlist;
	private inline function get_playlist() return session.playlist;

/* === Instance Fields === */

	public var provider : MediaProvider;
	public var mediaId:Null<String> = null;
	public var data(default, null):Null<TrackData> = null;

	public var media(default, null): Null<Media>;
	public var driver(default, null): Null<PlaybackDriver>;
	public var renderer(default, null): Null<MediaRenderer>;

	private var _ready : Bool = false;
	private var _loadingData : Bool = false;
	private var _dataLoaded : Signal<TrackData>;

/* === Class Methods === */

	// File => Track
	public static inline function fromFile(file : File):Track {
		return new Track(cast new LocalFileMediaProvider( file ));
	}
	
	// Url => Track
	public static inline function fromUrl(url : String):Track {
		return new Track(cast new HttpAddressMediaProvider( url ));
	}
}
