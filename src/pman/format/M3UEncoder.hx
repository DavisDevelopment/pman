package pman.utils;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.commands.Tools;

class M3UEncoder {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	public function encode(files : Array<File>):ByteArray {
		buffer = new ByteArrayBuffer();
		buffer.addString( '#EXTM3U\n' );
		for (file in files) {
			addFile( file );
		}
		return buffer.getByteArray();
	}
	private inline function addFile(file : File):Void {
		buffer.addString('\n#EXTINF:');
		buffer.addString('123,${file.path.name}\n');
		buffer.addString(file.path.toString() + '\n');
	}

	private var buffer : ByteArrayBuffer;

	public static inline function run(files : Array<File>):ByteArray {
		return new M3UEncoder().encode( files );
	}
}
