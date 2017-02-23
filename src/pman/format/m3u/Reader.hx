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

class M3UDecoder {
	/* Constructor Function */
	public function new():Void {
		buffer = new Stack();
		playlist = new Array();
	}

/* === Instance Methods === */

	/**
	  * decode the given String
	  */
	public inline function decodeString(s : String):Array<Path> {
		return decode(s.split( '\n' ));
	}

	/**
	  * decode the given Array of Strings
	  */
	public function decode(lines : Array<String>):Array<Path> {
		buffer = new Stack( lines );
		playlist = new Array();

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

			if (line.empty()) {
				parseNextLine();
			}
			else if (line.startsWith('#EXTINF:')) {
				var infoLine:String = line.after( '#EXTINF:' );
				line = nextLine();
				if (!line.empty()) {
					playlist.push(Path.fromString( line ));
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
	private var playlist : Array<Path>;

/* === Class Methods === */

	public static inline function run(s : String):Array<Path> {
		return new M3UDecoder().decodeString( s );
	}
}
