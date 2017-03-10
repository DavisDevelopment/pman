package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;

import haxe.Serializer;
import haxe.Unserializer;

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
	    if (deep && next != null) {
	        copy.next = next.clone();
	    }
	    return copy;
	}

    /**
      * check for equality
      */
    public inline function equals(other : Track):Bool {
        return (provider == other.provider);
    }

/* === Computed Instance Fields === */

	public var title(get, never):String;
	private inline function get_title():String return getName();

	public var uri(get, never):String;
	private inline function get_uri():String return getURI();

/* === Instance Fields === */

	public var provider : MediaProvider;
	public var next : Null<Track> = null;

	public var media(default, null): Null<Media>;
	public var driver(default, null): Null<PlaybackDriver>;
	public var renderer(default, null): Null<MediaRenderer>;

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
