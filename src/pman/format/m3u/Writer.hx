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

class Writer {
	/* Constructor Function */
	public function new():Void {
		//
	}

/* === Instance Methods === */

	public function encode(l : Playlist):ByteArray {
		buffer = '#EXTM3U\r';
		for (track in l) {
			addTrack( track );
		}
		var bytes = ByteArray.ofString(buffer);
		return bytes;
	}

	private inline function addTrack(track : Track):Void {
		buffer += '\r#EXTINF:';
		var sdur:String = '123';
		if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
			sdur = Std.string(track.data.meta.duration);
		}
		buffer += '$sdur,${track.title}\r';
		buffer += (track.uri + '\r');
	}

	private var buffer:String;

	public static inline function run(l : Playlist):ByteArray {
		return new Writer().encode(l);
	}
}