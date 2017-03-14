package pman.media;

import tannus.ds.Promise;
import tannus.sys.Path;
import tannus.http.Url;

import pman.core.*;
//import pman.media.LinkedPlaylist as Cpl;
import pman.media.PlaylistClass as Cpl;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:forward
//abstract Playlist (LinkedPlaylist) from LinkedPlaylist to LinkedPlaylist {
abstract Playlist (PlaylistClass) from PlaylistClass to PlaylistClass {
	/* Constructor Function */
	public inline function new(?tracks : Array<Track>):Void {
		this = new Cpl( tracks );
	}

/* === Instance Methods === */

	/**
	  * Array-like access to [this] Playlist's Tracks
	  */
	@:arrayAccess
	public inline function get(index : Int):Null<Track> {
		return this.get( index );
	}

/* === Static Methods === */

	/**
	  * build a Playlist from a JSON Array
	  */
	public static inline function fromJSON(dataStrings : Array<String>):Playlist {
		return Cpl.fromJSON( dataStrings );
	}
}
