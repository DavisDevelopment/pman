package pman.utils;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;

import Xml;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.commands.Tools;

class XSPFEncoder {
	/* Constructor Function */
	public function new():Void {
		
	}

/* === Instance Methods === */

	/**
	  * Encode the given Files
	  */
	public function encode(files : Array<File>):ByteArray {
		toXml( files );
		var el = tannus.xml.Elem.fromXml( root );
		var data:String = el.print( true );
		data = ('<?xml version="1.0" encoding="UTF-8"?>\n' + data);
		return ByteArray.ofString( data );
	}

	/**
	  * Encode the given FileList
	  */
	private function toXml(files : Array<File>):Xml {
		doc = Xml.createDocument();
		root = Xml.createElement( 'playlist' );
		doc.addChild( root );
		root.set('version', '1');
		root.set('xmlns', 'http://xspf.org/ns/0/');
		tracks = Xml.createElement( 'trackList' );
		root.addChild( tracks );
		for (file in files) {
			addFile( file );
		}
		return doc;
	}

	/**
	  * add a File to the Playlist
	  */
	private function addFile(file : File):Void {
		var track = Xml.parse('<track><location>file://${file.path}</location></track>').firstElement();
		tracks.addChild( track );
	}

/* === Instance Fields === */

	private var doc : Xml;
	private var root : Xml;
	private var tracks : Xml;

	public static inline function run(files : Array<File>):ByteArray {
		return new XSPFEncoder().encode( files );
	}
}
