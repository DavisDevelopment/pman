package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

import Xml;
import Xml.XmlType;
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
	  * read the given String as an xspf playlist
	  */
	public function read(s : String):Playlist {
		root = Xml.parse( s );
		playlist = new Playlist();

		walk( root );

		return playlist;
	}

	private function element(e : Xml):Void {
		switch (e.nodeName.toLowerCase()) {
			case 'playlist', 'tracklist':
				walk( e );

			case 'track':
				trackNode( e );

			default:
				null;
		}
	}

	private function trackNode(e : Xml):Void {
		var subs = e.elements();
		var info:Map<String, String> = new Map();
		for (n in subs) {
			info[n.nodeName] = text( n );
		}
		track( info );
	}

	private function track(info : Map<String, String>):Void {
		var t = info['location'].trim().parseToTrack();
		playlist.push( t );
	}

	private function node(x : Xml):Void {
		switch ( x.nodeType ) {
			case Element:
				element( x );

			default:
				null;
		}
	}

	private function walk(xmlNode : Xml):Void {
		for (n in xmlNode) {
			node( n );
		}
	}

	/**
	  * get the textual value of the given node
	  */
	private static function text(x : Xml):String {
		switch ( x.nodeType ) {
			case CData, PCData:
				return x.nodeValue;

			case Element:
				return (x.array().map(text).join(''));

			default:
				return '';
		}
	}

/* === Instance Fields === */

	private var root : Xml;
	private var playlist : Playlist;
}
