package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.format.m3u.Reader as M3UReader;
import pman.format.xspf.Reader as XSPFReader;
import pman.format.pls.Reader as PLSReader;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class FileListConverter {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */
	
	/**
	  * convert the given list of files into a Playlist
	  */
	public function convert(files : Array<File>):Playlist {
		fl = files;
		pl = new Playlist();

		for (file in fl) {
			_import( file );
		}

		return pl;
	}

	/**
	  * import the given file into the playlist, in the way most appropriate depending on the file
	  */
	private function _import(file : File):Void {
		switch ( file.path.extension ) {
			case 'mp4', 'webm', 'ogg', 'mp3', 'wav':
				var track = new Track(cast new LocalFileMediaProvider( file ));
				pl.push( track );

			case 'm3u':
				var reader = new M3UReader();
				var tracks = reader.read(file.lines());
				pl = pl.concat( tracks );

			case 'xspf':
				var reader = new XSPFReader();
				var tracks = reader.read(file.read().toString());
				pl = pl.concat( tracks );

			case 'pls':
				var reader = new PLSReader();
				var tracks = reader.read(file.lines());
				pl = pl.concat( tracks );

			default:
				throw 'what the fuck';
		}
	}

/* === Instance Fields === */

	private var fl : Array<File>;
	private var pl : Playlist;
}
