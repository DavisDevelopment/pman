package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

import Xml;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;

class Writer {
	/* Constructor Function */
	public function new():Void {
		
	}

/* === Instance Methods === */

	/**
	  * Encode the given Files
	  */
	public function encode(list : Playlist):ByteArray {
		toXml( list );
		var el = tannus.xml.Elem.fromXml( root );
		var data:String = el.print( true );
		data = ('<?xml version="1.0" encoding="UTF-8"?>\n' + data);
		return ByteArray.ofString( data );
	}

	/**
	  * Encode the given FileList
	  */
	private function toXml(list : Playlist):Xml {
		doc = Xml.createDocument();
		root = Xml.createElement( 'playlist' );
		doc.addChild( root );
		root.set('version', '1');
		root.set('xmlns', 'http://xspf.org/ns/0/');
		tracks = Xml.createElement( 'trackList' );
		root.addChild( tracks );
		for (track in list) {
		    addTrack( track );
		}
		return doc;
	}

	/**
	  * add a File to the Playlist
	  */
	private inline function addTrack(track : Track):Void {
		var track = Xml.parse('<track><location>${track.uri}</location></track>').firstElement();
		tracks.addChild( track );
	}

/* === Instance Fields === */

	private var doc : Xml;
	private var root : Xml;
	private var tracks : Xml;

/* === Static Methods === */

    /**
      * shorthand method for encoding an Array of tracks
      */
	public static inline function run(tracks : Playlist):ByteArray {
		return (new Writer().encode(tracks));
	}
}
