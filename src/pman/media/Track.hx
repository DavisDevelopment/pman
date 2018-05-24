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
import pman.bg.media.MediaFeature;
import pman.bg.media.MediaDataSource;
import pman.ui.pl.TrackView;
import pman.ui.*;
import pman.media.info.Mark;
import pman.media.info.*;
import pman.async.*;
import pman.async.tasks.*;
import pman.events.EventEmitter;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType as Either;

import electron.*;
import electron.Shell;
import electron.Tools.defer;
import Slambda.fn;
import tannus.math.TMath.*;
import pman.Globals.*;

import pman.media.TrackData2 as TrackData;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.ds.SortingTools;
using tannus.math.TMath;
using pman.bg.URITools;

//using pman.async.VoidAsyncs;
using tannus.async.Asyncs;

/**
  * pman.media.Track -- object that centralizes media playback state
  */
@:expose('PManTrack')
class Track extends EventDispatcher implements IComparable<Track> {
	/* Constructor Function */
	public function new(p:MediaProvider):Void {
	    super();

		provider = p;

        state = null;

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
	public inline function getName():String {
	    return provider.getName();
    }

	/**
	  * get the URI for [this] Track
	  */
	public inline function getURI():String {
	    return provider.getURI();
    }

    /**
      assign the media state's components
     **/
    public function patchMediaState(?m:Media, ?d:MediaDriver, ?r:MediaRenderer, ?rebuild:{?media:Bool,?renderer:Bool,?driver:Bool}, ?done:VoidCb):Void {
        if (!isMounted()) {
            throw 'Error: Track not mounted; cannot patch state';
        }
        else {
            state.set(m, d, r, rebuild, done);
        }
    }

	/**
	  * nullify the m,d,r fields
	  */
	public inline function nullify():Void {
	    if (state != null) {
	        state.nullify();
	        state = null;
	    }
	}

	/**
	  * deallocate the m,d,r fields
	  */
	public function deallocate(done: VoidCb):Void {
	    if (state != null) {
	        state.deallocate( done );
	    }
        else {
            done();
        }
	}

	/**
	  * load the mediaContext data onto [this] Track
	  */
	public function mount(done: VoidCb):Void {
	    /*
	    vsequence(function(add, exec) {
			//add(next -> loadTrackMediaState());
			add(fn(f => loadTrackMediaState(f.wrap(function(_, ?error) {
			    if (error != null) {
			        dismount( VoidCb.noop );
			    }
                else {
                    if (hasFeature(PlayEvent)) {
                        var ps = driver.getPlaySignal();
                        ps.on(function() {
                            player.dispatch('play', null);
                        });
                    }
                }
                _( error );
			}))));
			//TODO seems like there should be more to do here..
			exec();
	    }, done);
	    */

	    TrackMediaState.loadMediaState(provider, function(?error, ?state) {
	        if (error != null) {
	            dismount( VoidCb.noop );
	            done( error );
	        }
            else {
                this.state = state;
                if (hasFeature(PlayEvent)) {
                    var ps = driver.getPlaySignal();
                    ps.on(function() {
                        player.dispatch('play', null);
                    });
                }
                done();
            }
	    });
	}

	/**
	  * the inverse effect of 'mount'
	  */
	public function dismount(done: VoidCb):Void {
		deallocate(done.wrap(function(f, ?e) {
		    nullify();
		    f( e );
		}));
	}

	/**
	  * check whether [this] Track is mounted
	  */
	public inline function isMounted():Bool {
	    return (state != null);
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
                            updateView();
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
      * perform some check on [data]
      */
    public function dataCheck(?checks: Either<String, Array<String>>):Bool {
        if (data != null && !data.isEmpty()) {
            if (checks != null) {
                var props:Array<String> = new Array();
                if ((checks is String)) {
                    props.push(cast checks);
                }
                else if ((checks is Array<String>)) {
                    props = props.concat(cast checks);
                }
                var tmp = props.copy();
                props = [];
                for (x in props) {
                    if (x.has(',')) {
                        props = props.concat(x.split(',').filter.fn(_.hasContent()));
                    }
                }
                return data.checkProps( props );
            }
            else {
                return data.isReady();
            }
        }
        else {
            return false;
        }
    }

    /**
      * update [this]'s view, if it exists
      */
    public inline function updateView():Void {
        var tv = getView();
        if (tv != null) {
            tv.update();
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

            mt.push({
                label: 'Edit Info',
                click: function(i, w, e) {
                    _edit();
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
    private function _delete(?done : VoidCb):Void {
        if (done == null)
            done = done.nn();

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

    /**
      * open prompt to edit [this] Track
      */
    private function _edit(?done:VoidCb):Void {
        if (done == null) {
            done = VoidCb.noop;
        }

        vsequence(function(add, exec) {
            add( fillData );
            add(function(next) {
                trace('fillData completed');
                defer(function() {
                    var editor = new TrackInfoPopup( this );
                    editor.open();
                    editor.once('close', untyped function() {
                        trace('Betty, poop dew');
                        next();
                    });
                });
            });

            exec();
        }, done);
    }

/* === TrackData Methods === */

    /**
      * shorthand method to edit the TrackData for [this] Track
      */
    public function editData(action:TrackData->VoidCb->Void, ?complete:VoidCb, ?save:Bool, ?reqProps:Array<String>):Void {
        if (complete == null) {
            complete = (function(?error) {
                if (error != null)
                    report( error );
            });
        }

        vsequence(function(add, exec) {
            var data: TrackData;
            add(function(next) {
                getData(function(?err, ?dat) {
                    if (err != null) {
                        return next( err );
                    }
                    else {
                        data = dat;
                        data.onReady(next.void());
                    }
                });
            });
            add(function(next) {
                if (reqProps.hasContent()) {
                    data.resample(data.getPropertyNames().concat(reqProps), function(?error) {
                        if (error != null) {
                            return next( error );
                        }
                        else {
                            //...
                            next();
                        }
                    });
                }
                else {
                    next();
                }
            });
            add(function(next) {
                data.edit(action, next, save);
            });

            defer(function() exec());
        }, complete);
    }

    /**
      * ensure data has all fields
      */
    public function fillData(done: VoidCb):Void {
        getData(function(?error, ?data:TrackData) {
            if (error != null) {
                done( error );
            }
            else {
                data.fill( done );
            }
        });
    }

    /**
      * get the Path to [this]
      */
    public function getFsPath():Null<Path> {
        switch ( source ) {
            case MediaSource.MSLocalPath(path): 
                return path.toUri().toFilePath();

            case MediaSource.MSUrl(url):
                if (url.isPath() || url.protocol() == 'file') {
                    return url.toUri().toFilePath();
                }
                else {
                    return null;
                }
            
            default:
                throw 'What the fuck?';
        }
    }

    /**
      * check whether [this] Track references a real file
      */
    public function isRealFile():Bool {
        var path:Null<Path> = getFsPath();
        if (path != null) {
            return FileSystem.exists(path + '');
        }
        else return false;
    }

    /**
      * set whether [this] Track is starred
      */
    public function setStarred(value:Bool, ?done:VoidCb):Void {
        if (done == null)
            done = VoidCb.noop;
        done = done.wrap(function(f, ?error) {
            defer( updateView );
            f( error );
        });
        editData(function(i, next) {
            i.starred = value;

            next();
        }, done);
    }

    /**
      * toggle the value of [this]'s starred property
      */
    public function toggleStarred(?done: VoidCb):Void {
        if (done == null)
            done = VoidCb.noop;

        done = done.wrap(function(_, ?error) {
            defer( updateView );
            _(error);
        });

        var val:Bool = false;
        editData(function(i, next) {
            val = (i.starred = !i.starred);

            next();
        }, 
        function(?error) {
            done( error );
        });
    }

    /**
      * set [starred] to `true`
      */
    public inline function star(?done : VoidCb):Void {
        setStarred(true, done);
    }

    /**
      * set [starred] to `false`
      */
    public inline function unstar(?done : VoidCb):Void {
        setStarred(false, done);
    }

    /**
      * add a Mark to [this] Track
      */
    public function addMark(mark:Mark, ?done:VoidCb):Void {
        editData(function(i, next) {
            i.addMark( mark );

            next();
        }, done);
    }

    /**
      * capture screenshot of given size, at given time
      */
    @:deprecated
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
    @:deprecated
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
      * check for presence of the given MediaFeature
      */
    public inline function hasFeature(feature: MediaFeature):Bool {
        return (features.exists( feature ) && features.get( feature ));
    }

    /**
      * check for presence of all of the given MediaFeature's
      */
    public function hasFeatures(feats: Iterable<MediaFeature>):Bool {
        return feats.all.fn(hasFeature( _ ));
    }

    /**
      * check for presence of at least one of the given MediaFeatures
      */
    public function hasAnyFeatures(feats: Iterable<MediaFeature>):Bool {
        return feats.any.fn(hasFeature( _ ));
    }

    /**
      * check whether [this] Track is missing any of the given MediaFeatures
      */
    public inline function isMissingAnyFeatures(feats: Iterable<MediaFeature>):Bool {
        return !hasFeatures( feats );
    }

    /**
      * check whether [this] Track is missing all of the given MediaFeatures
      */
    public inline function isMissingFeatures(feats: Iterable<MediaFeature>):Bool {
        return !hasAnyFeatures( feats );
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

	public var features(get, never):Dict<MediaFeature, Bool>;
	private inline function get_features() {
	    return untyped (driver || media || provider).features;
		//if (driver != null)
			//return driver.features;
        //else if (media != null)
            //return media.features;
        //else return provider.features;
	}

    public var media(get, never): Null<Media>;
    private inline function get_media() return (state != null ? state.media : null);

    public var renderer(get, never): Null<MediaRenderer>;
    private inline function get_renderer() return (state != null ? state.renderer : null);

    public var driver(get, never): Null<MediaDriver>;
    private inline function get_driver() return (state != null ? state.driver : null);
	//public var driver(default, null): Null<MediaDriver>;
	//public var renderer(default, null): Null<MediaRenderer>;

/* === Instance Fields === */

	public var provider : MediaProvider;
	public var mediaId:Null<String> = null;
	public var data(default, null):Null<TrackData> = null;

	//public var media(default, null): Null<Media>;
	//public var driver(default, null): Null<MediaDriver>;
	//public var renderer(default, null): Null<MediaRenderer>;
	public var state(default, null): Null<TrackMediaState>;

	private var _ready : Bool = false;
	private var _loadingData : Bool = false;
	private var _dataLoaded : Signal<TrackData>;

/* === Class Methods === */

	// File => Track
	public static inline function fromFile(file : File):Track {
		return new Track(cast new LocalFileMediaProvider( file ));
	}
	
	// Url => Track
	public static function fromUrl(url : String):Track {
		return new Track(cast new HttpAddressMediaProvider( url ));
	}
}

/**
  purpose of class
 **/
class TrackMediaState extends EventEmitter {
    /* Constructor Function */
    public function new(m:Media, d:MediaDriver, r:MediaRenderer):Void {
        super();

        media = m;
        driver = d;
        renderer = r;

        addSignal('change:media', new Signal2<Media, Media>());
        addSignal('change:driver', new Signal2<MediaDriver, MediaDriver>());
        addSignal('change:renderer', new Signal2<MediaRenderer, MediaRenderer>());
    }

/* === Instance Methods === */

    /**
      deallocate and deactivate [this] MediaState
     **/
    public function deallocate(done: VoidCb):Void {
        vbatch(function(add, exec) {
            add( media.dispose );
            add( driver.dispose );
            add( renderer.dispose );
            exec();
        }, done);
    }

    /**
      nullify all of [this]'s fields
     **/
    public inline function nullify():Void {
        media = null;
        driver = null;
        renderer = null;
    }

    /**
      reassign [this]'s fields
     **/
    public function set(?m:Media, ?d:MediaDriver, ?r:MediaRenderer, ?rebuild:{?media:Bool,?renderer:Bool,?driver:Bool}, ?done:VoidCb):Void {
        done = ensureVcb( done );
        if (rebuild == null)
            rebuild = {};
        vsequence(function(add, exec) {
            if (m != null) {
                add(setMedia.bind(m, rebuild.media, _));
            }
            if (d != null) {
                add(setDriver.bind(d, rebuild.driver, _));
            }
            if (r != null) {
                add(function(next) {
                    setRenderer( r );
                    next();
                });
            }
            exec();
        }, done);
    }

    public function setMedia(m:Media, rebuild:Bool=false, ?callback:VoidCb):Void {
        /* assign the field value */
        beforeAfter(
            Getter.create(media),
            function() {
                media = m;
            },
            a -> a.with([x, y], dispatch('change:media', x, y))
        );

        /* handle the callback */
        callback = ensureVcb( callback );

        if ( rebuild ) {
            var rethrow = callback.raise();
            ph(media.getDriver(), rethrow, function(dr) {
                driver = dr;
                ph(media.getRenderer(driver), rethrow, function(re) {
                    renderer = re;
                    callback();
                });
            });
        }
        else {
            callback();
        }
    }

    /**
      reassign [this]'s [driver] field
     **/
    public function setDriver(d:MediaDriver, rebuild:Bool=false, ?callback:VoidCb):Void {
        beforeAfter(
            Getter.create(driver),
            function() {
                driver = d;
            },
            a -> a.with([x, y], dispatch('change:driver', x, y))
        );
        callback = ensureVcb( callback );

        if ( rebuild ) {
            var rethrow = callback.raise();
            ph(media.getRenderer( driver ), rethrow, function(re) {
                renderer = re;

                callback();
            });
        }
        else {
            callback();
        }
    }

    /**
      reassign [this]'s [renderer] field
     **/
    public function setRenderer(r: MediaRenderer):Void {
        beforeAfter(
            Getter.create(renderer),
            function() {
                renderer = r;
            },
            a -> a.with([x, y], dispatch('change:renderer', x, y))
        );
    }

    /**
      utility method used to simplify calculating deltas
     **/
    private static function beforeAfter<T>(v:Getter<T>, f:Void->Void, ?df:Array<T>->Void):Array<T> {
        var a:Array<T> = [v.get()];
        f();
        a.push(v.get());
        if (df != null) {
            df( a );
        }
        return a;
    }

    private static function calc_delta<T>(v:Getter<T>, f:Void->Void, ?df:Delta<T>->Void):Delta<T> {
        var a = beforeAfter(v, f);
        var d = a.with([from_, to_], new Delta(to_, from_));
        if (df != null) {
            df( d );
        }
        return d;
    }

    private function onDelta2<T>(name:String, f:Delta<T>->Void):Void {
        on(name, function(a:T, b:T) {
            f(new Delta(b, a));
        });
    }

	/**
	  * load [this]'s state
	  */
	public static function loadMediaState(provider:MediaProvider, ?callback:Cb<TrackMediaState>):Promise<TrackMediaState> {
	    return new Promise(function(accept, reject) {
            var m:Media, d:MediaDriver, r:MediaRenderer;
            ph(provider.getMedia(), reject, function(me) {
                m = me;
                ph(m.getDriver(), reject, function(dr) {
                    d = dr;
                    ph(m.getRenderer(d), reject, function(re) {
                        r = re;

                        accept(new TrackMediaState(m, d, r));
                    });
                });
            });
        }).toAsync( callback );
	}

    /**
      utility method for dealing with promises
     **/
	private static inline function ph<T>(p:Promise<T>, rethrow:Dynamic->Void, handler:T->Void):Promise<T> {
	    return p.then(handler, rethrow);
	}

	private static function ensureVcb(?callback: VoidCb):VoidCb {
        if (callback == null) {
            callback = VoidCb.noop;
        }
        callback = callback.wrap(function(_, ?error) {
            if (error != null) {
                report( error );
            }
            _( error );
        });
        return callback;
	}

/* === Instance Fields === */

    public var media(default, null): Media;
    public var driver(default, null): MediaDriver;
    public var renderer(default, null): MediaRenderer;
}
