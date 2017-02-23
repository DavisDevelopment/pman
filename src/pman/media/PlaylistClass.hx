package pman.media;

import tannus.io.*;
import tannus.ds.Promise;
import tannus.sys.Path;
import tannus.http.Url;

import haxe.Serializer;
import haxe.Unserializer;

import pman.core.*;
import pman.media.PlaylistChange;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * PlaylistClass -- Object used to hold an ordered list of multiple Track objects
  */
class PlaylistClass {
	/* Constructor Function */
	public function new(?a : Array<Track>):Void {
		l = (a != null ? a.copy() : new Array());

		changeEvent = new Signal();
	}

/* === Instance Methods === */

	/**
	  * get a Track from [this] Playlist at the given index
	  */
	public inline function get(index : Int):Null<Track> {
		return l[ index ];
	}

	/**
	  * create and return a new Playlist by combining [this] one and [other]
	  */
	public function concat(other : Playlist):Playlist {
		return new Playlist(l.concat( other.l ));
	}

	/**
	  * create and return a copy of [this] Playlist
	  */
	public function copy():Playlist {
		return new Playlist(l.copy());
	}

	/**
	  * Clear [this] Playlist -- alters [this] object in place
	  */
	public function clear():Void {
		l = new Array();
		change( PCClear );
	}

	/**
	  * filter [this] Playlist
	  */
	public function filter(f : Track -> Bool):Playlist {
		return new Playlist(l.filter( f ));
	}

	/**
	  * get the index of the given Track
	  */
	public function indexOf(track : Track):Int {
		return l.indexOf( track );
	}

	/**
	  * insert the given Track at the given position
	  */
	public function insert(pos:Int, track:Track, report:Bool=true):Void {
		l.insert(pos, track);
		if ( report ) {
			change(PCInsert(pos, track));
		}
	}

	/**
	  * move the given Track to the given index
	  */
	public function move(track:Track, pos:Void->Int, report:Bool=true):Void {
		if (l.has( track )) {
			var oldPos:Int = indexOf( track );
			remove(track, false);
			var newPos:Int = pos();
			insert(newPos, track, false);
			if ( report ) {
				change(PCMove(track, oldPos, newPos));
			}
		}
	}

	/**
	  * iterate over [this] Playlist's Tracks
	  */
	public inline function iterator():Iterator<Track> {
		return l.iterator();
	}

	/**
	  * get the last index at which [track] can be found in [this] Playlist
	  */
	public inline function lastIndexOf(track : Track):Int {
		return l.lastIndexOf( track );
	}

	/**
	  * map [this] Playlist
	  */
	public inline function map<T>(f : Track -> T):Array<T> {
		return l.map( f );
	}

	/**
	  * remove and return the last Track in [this] Playlist
	  */
	public function pop():Null<Track> {
		var t = l.pop();
		if (t != null) {
			change(PCPop( t ));
		}
		return t;
	}

	/**
	  * add [track] to the end of [this] Playlist
	  */
	public function push(track : Track):Int {
		var n = l.push( track );
		change(PCPush( track ));
		return n;
	}

	/**
	  * delete [track] from [this] Playlist
	  */
	public function remove(track:Track, report:Bool=true):Bool {
		var status = l.remove( track );
		if (status && report) {
			change(PCRemove( track ));
		}
		return status;
	}

	/**
	  * reverse [this] Playlist's contents, in place
	  */
	public function reverse():Void {
		l.reverse();
		change( PCReverse );
	}

	/**
	  * remove and return the first Track in [this] Playlist
	  */
	public function shift():Null<Track> {
		var t = l.shift();
		if (t != null) {
			change(PCShift( t ));
		}
		return t;
	}

	/**
	  * get a slice of [this] Playlist
	  */
	public function slice(pos:Int, ?end:Int):Playlist {
		return new Playlist(l.slice(pos, end));
	}

	/**
	  * sort [this] Playlist
	  */
	public function sort(f : Track->Track->Int):Void {
		l.sort( f );
		change(PCSort( f ));
	}

	/**
	  * splice [this] Playlist
	  */
	public function splice(pos:Int, len:Int):Playlist {
		var sub = l.splice(pos, len);
		return new Playlist( sub );
	}

	/**
	  * convert [this] Playlist to a String
	  */
	public function toString():String {
		return 'Playlist';
	}

	/**
	  * get the Array of Tracks
	  */
	public inline function toArray():Array<Track> {
		return l;
	}

	/**
	  * report a change in [this] Playlist
	  */
	private inline function change(c : PlaylistChange):Void {
		changeEvent.call( c );
	}

/* === Serialization Methods === */

	@:keep
	public function hxSerialize(s : Serializer):Void {
		return ;
	}

	@:keep
	public function hxUnserialize(u : Unserializer):Void {
		return ;
	}

	/**
	  * Convert [this] to a JSON Array
	  */
	public function toJSON():Array<String> {
		return map.fn(Serializer.run( _ ));
	}

/* === Computed Instance Fields === */

	// the number of items in [this] Playlist
	public var length(get, never):Int;
	private inline function get_length():Int return l.length;

/* === Instance Fields === */

	// the Signal fired when [this] Playlist changes
	public var changeEvent : Signal<PlaylistChange>;

	// the Array of Tracks in [this] Playlist
	private var l : Array<Track>;

/* === Class Methods === */

	/**
	  * Build a Playlist from a JSON array
	  */
	public static function fromJSON(dataStrings : Array<String>):PlaylistClass {
		var tracks:Array<Track> = new Array();
		for (ds in dataStrings) {
			var track:Track = Unserializer.run( ds );
			tracks.push( track );
		}
		return new PlaylistClass( tracks );
	}
}
