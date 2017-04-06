package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.media.MediaType;
import pman.async.*;
import pman.ui.pl.TrackView;
import pman.media.info.Mark;

import haxe.Serializer;
import haxe.Unserializer;

import electron.*;
import electron.Tools.defer;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

/**
  * pman.media.Track -- object that centralizes media playback state
  */
class Track {
	/* Constructor Function */
	public function new(p:MediaProvider):Void {
		provider = p;

		media = null;
		driver = null;
		renderer = null;
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
	    return copy;
	}

    /**
      * check for equality
      */
    public inline function equals(other : Track):Bool {
        return (provider == other.provider);
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
    public function getData(callback : TrackData->Void):Void {
        if (data == null) {
            var loader = new TrackDataLoader(this, BPlayerMain.instance.db.mediaStore);
            var dp = loader.load();
            dp.then(function( data ) {
                this.data = data;
                var v = getView();
                if (v != null) {
                    v.update();
                }
                callback( data );
            });
        }
        else {
            defer(callback.bind( data ));
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
        getData(function( data ) {
            var mt:MenuTemplate = new MenuTemplate();

            mt.push({
                label: 'Play',
                click: function(i,w,e) player.openTrack( this )
            });
            mt.push({
                label: 'Play Next',
                click: function(i,w,e) playlist.move(this, fn(session.indexOfCurrentMedia() + 1))
            });
            mt.push({
                label: 'Remove from Playlist',
                click: function(i,w,e) {
                    playlist.remove( this );
                }
            });
            mt.push({
                label: (data != null && data.starred ? 'Unfavorite' : 'Favorite'),
                click: function(i,w,e) {
                    toggleStarred();
                }
            });

            callback( mt );
        });
    }

/* === TrackData Methods === */

    /**
      * shorthand method to edit the TrackData for [this] Track
      */
    public function editData(action:TrackData->Void, ?complete:Void->Void):Void {
        getData(function(data : TrackData) {
            action( data );
            data.save(function() {
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
	public var data(default, null):Null<TrackData> = null;

	public var media(default, null): Null<Media>;
	public var driver(default, null): Null<PlaybackDriver>;
	public var renderer(default, null): Null<MediaRenderer>;

	private var _ready : Bool = false;

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
