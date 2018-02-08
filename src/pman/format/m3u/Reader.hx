package pman.format.m3u;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.media.MediaTools;

class Reader {
	/* Constructor Function */
	public function new():Void {
		buffer = new Stack();
		playlist = new Playlist();
	}

/* === Instance Methods === */

	/**
	  * decode the given String
	  */
	public inline function readString(s : String):Playlist {
		return read(s.split( '\n' ));
	}

	/**
	  * decode the given Array of Strings
	  */
	public function read(lines : Array<String>):Playlist {
		buffer = new Stack( lines );
		playlist = new Playlist();

		parse();

		return playlist;
	}

	/**
	  * parse the buffer
	  */
	private function parse():Void {
		while ( !buffer.empty ) {
			parseNextLine();
		}
	}

	/**
	  * parse and process the next line of input
	  */
	private function parseNextLine():Void {
		if ( buffer.empty ) {
			return ;
		}
		else {
			var line:String = nextLine();

			if (!line.hasContent()) {
				parseNextLine();
			}
			else if (line.startsWith('#EXTINF:')) {
				var infoLine:String = line.after( '#EXTINF:' );
				line = nextLine();
				if (!line.empty()) {
				    var src:Null<MediaSource> = null;
				    if (line.isPath()) {
				        src = line.toFilePath().toMediaSource();
				    }
                    else if (line.isUri()) {
                        src = line.toMediaSource();
                    }
                    else {
                        throw 'M3UErrorInvalidEntryError: "$line" cannot be resolved to a media resource';
                    }

					var track:Track = src.toTrack();
					playlist.push( track );
				}
				nextLine();
			}
		}
	}

	/**
	  * get the next line of text
	  */
	private function nextLine():String {
		var line = buffer.pop();
		if (line == null) line = '';
		return line.trim();
	}

/* === Instance Fields === */

	private var buffer : Stack<String>;
	private var playlist : Playlist;

/* === Class Methods === */

	/**
	  * shorthand to create a new Reader instance, and use it to decode the given String
	  */
	public static inline function run(s : String):Playlist {
		return new Reader().readString( s );
	}
}
