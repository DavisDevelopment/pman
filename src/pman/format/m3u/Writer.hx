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

	}

/* === Instance Methods === */

	public function encode(pl : Playlist):ByteArray {
		buffer = new ByteArrayBuffer();
		buffer.addString( '#EXTM3U\n' );
		for (t in pl) {
			addTrack( t );
		}
		return buffer.getByteArray();
	}
	private inline function addTrack(track : Track):Void {
		buffer.addString('\n#EXTINF:');
		buffer.addString('123,${track.title}\n');
		buffer.addString(track.provider.getURI() + '\n');
	}

	private var buffer : ByteArrayBuffer;

	public static inline function run(pl : Playlist):ByteArray {
	    return new Writer().encode( pl );
	}
}
