package pman.display;

import tannus.io.*;
import tannus.ds.*;
import tannus.graphics.Color;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class ColorScheme {
	/* Constructor Function */
	public function new():Void {
		derived = new Dict();
		did = 0;
		colors = new Array();
		colors.push(new Color(34, 34, 34));
		colors.push(new Color(242, 122, 72));
		colors.push(new Color(230, 230, 230));
	}

/* === Instance Methods === */

	/**
	  * Cache the given Color, and return it's id
	  */
	public function save(c : Color):Int {
		var id:Int = did++;
		derived[id] = c;
		return id;
	}

	/**
	  * Get a cached color
	  */
	public inline function restore(id : Int):Null<Color> {
		return derived[ id ];
	}

	/**
	  * Check for the given id
	  */
	public inline function exists(id : Int):Bool {
		return derived.exists( id );
	}

/* === Computed Instance Fields === */

	public var primary(get, never):Color;
	private inline function get_primary():Color return colors[0];

	public var secondary(get, never):Color;
	private inline function get_secondary():Color return colors[1];

	public var tertiary(get, never):Color;
	private inline function get_tertiary():Color return colors[2];

/* === Instance Fields === */

	public var colors : Array<Color>;
	private var derived : Dict<Int, Color>;
	private var did : Int;
}
