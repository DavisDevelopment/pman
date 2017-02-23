package pman.display;

import gryffin.display.*;

import vex.core.*;

import tannus.io.*;
import tannus.ds.*;
import tannus.internal.CompileTime in Ct;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class Icons {
	/**
	  * Play icon
	  */
	public static function playIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'play', f);
	}

	/**
	  * Pause icon
	  */
	public static function pauseIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'pause', f);
	}
	public static function prevIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'previous', f);
	public static function nextIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'next', f);
	public static function expandIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'expand', f);
	public static function collapseIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'collapse', f);
	public static function clockIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'clock', f);
	public static function muteIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'sound-muted', f);
	public static function shuffleIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'shuffle', f);
	public static function backIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'back', f);
	public static function volumeIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'sound3', f);
	}

	/**
	  * create the Chromecast icon
	  */
	public static function castIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'cast', f);
	}

	/**
	  * Utility method for creating a <path> from a command string stored in [icon_data]
	  */
	public static function namedPath(w:Int, h:Int, name:String, ?f:Path->Void):Document {
		return spath(w, h, icon_data.get( name ), f);
	}

	/**
	  * Utility method for creating a <path> from a command string
	  */
	public static function spath(w:Int, h:Int, d:String, ?f:Path->Void):Document {
		return path(w, h, function(p) {
			p.d = d;
			p.style.fill = '#E6E6E6';
			if (f != null) f( p );
		});
	}

	/**
	  * Utility method for creating an svg document whose sole element is a <path>
	  */
	public static function path(w:Int, h:Int, f:Path->Void):Document {
		return icon(w, h, function( svg ) {
			var path = new Path();
			svg.append( path );
			f( path );
		});
	}
	
	/**
	  * Utility method for creating an svg document
	  */
	public static function icon(w:Int, h:Int, f:Document->Void):Document {
		var svg = new Document();
		svg.width = w;
		svg.height = h;
		svg.viewBox = [76, 76];

		f( svg );

		return svg;
	}

	/**
	  * get some icon-data by name
	  */
	private static function get(name : String):String {
		return icon_data.get( name );
	}

	/**
	  * Initialize [this] class
	  */
	public static function __init__():Void {
		icon_data = Ct.readJSON( 'assets/icons/icon_data.json' );
		/*
		var rd:Object = new Object( raw_icon_data );
		icon_data = new Dict();
		for (key in rd.keys) {
			icon_data.set(key, rd.get( key ));
		}
		*/
	}

/* === Static Fields === */

	private static var icon_data : Object;
}
