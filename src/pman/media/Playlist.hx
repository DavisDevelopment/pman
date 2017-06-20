package pman.media;

import tannus.ds.Set;
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
using pman.media.MediaTools;

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

	@:to
	public inline function toArray():Array<Track> return this.toArray();

	@:to
	public inline function toSet():Set<Track> return this.toSet();

	@:to
	public inline function toMediaSourceList():MediaSourceList return this.toMediaSourceList();

	@:to
	public inline function toStrings():Array<String> return toMediaSourceList().toStrings();

	@:from
	public static inline function fromIterable<T:Iterable<Track>>(i : T):Playlist return new Playlist(i.array());

	@:from
	public static inline function fromMediaSourceList(msl : MediaSourceList):Playlist return PlaylistClass.fromMediaSourceList(msl);

	@:from
	public static inline function fromStrings<T:Iterable<String>>(s : T):Playlist return PlaylistClass.fromStrings(s);

/* === Static Methods === */

	/**
	  * build a Playlist from a JSON Array
	  */
	public static inline function fromJSON(dataStrings : Array<String>):Playlist {
		return Cpl.fromJSON( dataStrings );
	}
}
