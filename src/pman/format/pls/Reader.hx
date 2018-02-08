package pman.format.pls;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.format.ini.Data;
import pman.format.ini.Data.ININode;
import pman.format.ini.Reader as INIReader;

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

	}

/* === Instance Methods === */

	/**
	  * parse the given input lines as a PLS formatted Playlist
	  */
	public function read(lines : Array<String>):Playlist {
	    var playlist = new Playlist();
		var ini = INIReader.run( lines );
		var pls = ini.section( 'playlist' );
		if (pls == null) {
		    malformed();
		}
		else {
		    var pm:Map<String, String> = pls.propsMap();
			var noe:Null<Int> = (pm.exists('NumberOfEntries') ? Std.parseInt(pm.get('NumberOfEntries')) : null);
			inline function iget(key:String, index:Int){
			    return pm[(key + index)];
			}
			if (noe == null) {
			    malformed();
			}
            else {
                for (i in 0...noe) {
                    var location:String = iget('File', i+1);
                    //TODO actually use the other extracted values somehow
                    var title:Null<String> = iget('Title', i+1);
                    var slength:Null<String> = iget('Length', i+1);
                    var track:Track = location.toTrack();
                    playlist.push( track );
                }
            }
		}
		return playlist;
	}

	/**
	  * parse the given String into a PLS formatted playlist
	  */
	public inline function readString(s : String):Playlist return read(s.split('\n'));

	private inline function malformed():Void {
		throw 'ParsingError(PLS): Malformed PLS data';
	}

/* === Instance Fields === */

/* === Static Methods === */

    public static inline function run(s : String):Playlist return (new Reader().readString( s ));
}
