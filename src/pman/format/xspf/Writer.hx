package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.bg.media.*;
import pman.format.xspf.Data;

import Xml;
import haxe.xml.Printer as XmlPrinter;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using edis.xml.XmlTools;
using DateTools;

class Writer {
	/* Constructor Function */
	public function new():Void {
		//TODO
	}

/* === Instance Methods === */

	/**
	  * Encode the given Files
	  */
	public function encode(list: Data):ByteArray {
		toXml( list );
		//var el = tannus.xml.Elem.fromXml( root );
		//var data:String = el.print( true );
		var data:String = XmlPrinter.print(doc, false);
		data = ('<?xml version="1.0" encoding="UTF-8"?>\n' + data);
		return ByteArray.ofString( data );
	}

	/**
	  * Encode the given FileList
	  */
	private function toXml(list : Data):Xml {
		doc = Xml.createDocument();
		root = Xml.createElement( 'playlist' );
		doc.addChild( root );
		root.set('version', '1');
		root.set('xmlns', 'http://xspf.org/ns/0/');
		generatePlaylistHeader( list );
		tracks = Xml.createElement( 'trackList' );
		root.addChild( tracks );

		for (track in list.tracks) {
		    addTrack( track );
		}
		return doc;
	}

	/**
	  * add a File to the Playlist
	  */
	private function addTrack(track : DataTrack):Void {
		//var track = Xml.parse('<track><location>${track.uri}</location></track>').firstElement();
		var node = Xml.createElement( 'track' );
		inline function sub(type:String, data:Null<Dynamic>) {
		    if (data != null) {
                var child = node.childElement( type );
                child.text(Std.string( data ));
                return child;
            }
            else return null;
		}
		    
        sub('title', track.title.nullEmpty());
        sub('duration', track.duration);
        for (loc in track.locations) {
            sub('location', loc);
        }
        sub('creator', track.creator);
        sub('annotation', track.annotation);
        sub('image', track.image);
        sub('album', track.album);
        sub('info', track.info);
        sub('trackNum', track.trackNum);

        
        if (track.extensions.hasContent()) {
            for (ext in track.extensions) {
                node.childElement('extension', ["application" => ext.application]).addChild( ext.node );
            }
        }
        
		tracks.addChild( node );
	}

	private function generatePlaylistHeader(list: Data):Void {
		inline function sub(type:String, data:Null<Dynamic>) {
		    if (data != null) {
                var child = root.childElement( type );
                child.text(Std.string( data ));
                return child;
            }
            else return null;
		}

        sub('title', list.title);
        sub('creator', list.creator);
        sub('annotation', list.annotation);
        sub('info', list.info);
        sub('location', list.location);
        sub('image', list.image);
	}

	private function toISOString(d: Date):String {
	    throw 'TODO';
	}

/* === Instance Fields === */

	private var doc : Xml;
	private var root : Xml;
	private var tracks : Xml;

/* === Static Methods === */

    /**
      * shorthand method for encoding an Array of tracks
      */
	public static inline function run(tracks : Data):ByteArray {
		return (new Writer().encode(tracks));
	}
}
