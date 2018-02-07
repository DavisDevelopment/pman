package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.bg.media.*;
import pman.format.xspf.Data;

import edis.xml.*;

import Xml;
import Xml.XmlType;
import Slambda.fn;
import tannus.io.Ptr.*;

import haxe.macro.Expr;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.bg.URITools;
using pman.bg.PathTools;
using edis.xml.XmlTools;

@:noPackageRestrict
class Reader extends BaseXmlParser {
	/* Constructor Function */
	public function new():Void {
	    super();
	}

/* === Instance Methods === */

    public function parseString(xmlString: String):Data {
        doc = null;
        handleString( xmlString );
        return doc;
    }

    /**
      * pull from a ByteArray
      */
    public function read(data: ByteArray):Data {
        return parseString(data.toString());
    }

    /**
      * set up the parsing procedures
      */
    override function setup():Void {
        on('playlist', parsePlaylistNode);
        onElement(function(node) {
            trace( node );
        });
    }

    /**
      * handles parsing of the playlist node
      */
    private function parsePlaylistNode(playlist: FunctionalNodeHandler):Void {
        doc = new Data();
        var txt = (n:String, f:String->Void) -> playlist.childGetText(n, (s:String)->f(s.trim()));
        
        txt('title', fn(doc.title = _));
        txt('creator', fn(doc.creator = _));
        txt('annotation', fn(doc.annotation = _));
        txt('info', fn(doc.info = _));
        //TODO etc...

        playlist.on('trackList', parseTrackListNode);
    }

    /**
      * handles parsing of the trackList node
      */
    private function parseTrackListNode(l: FunctionalNodeHandler):Void {
        l.on('track', function(_node) {
            parseTrackNode(_node, function(t: Null<DataTrack>) {
                if (t != null) {
                    doc.addTrack( t );
                }
            });
        });
    }

    /**
      * parses each <track/> node
      */
    private function parseTrackNode(tn:FunctionalNodeHandler, f:Null<DataTrack>->Void):Void {
        var num = tn.childGetTextAsFloat.bind(_, _), inum = tn.childGetTextAsInt.bind(_, _);
        inline function txt(n:String, f:String->Void) {
            tn.childGetText(n, function(s) {
                f(echo(s.trim()));
            });
        }
        var track = doc.createTrack();

        txt('title', setr(track.title));
        txt('location', uri->track.addLocation( uri ));
        inum('duration', setr(track.duration));

        tn.then(function() {
            if (track.locations.hasContent()) {
                f( track );
            }
            else {
                f( null );
            }
        });
    }

    //private static macro function ex(f:Expr, ctx:Expr, id:Expr) {
        //return macro ($f('$id', x->$ctx.$id=x));
    //}

    private var doc: Data;
}
