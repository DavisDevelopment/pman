package ida.backend.idb;

import tannus.ds.*;
import tannus.io.Signal;
import tannus.io.VoidSignal;
import tannus.html.Win;

import js.html.idb.*;
import js.html.DOMError;
import haxe.Constraints.Function;

import ida.Utils;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using ida.Utils;

class IDBKeyRange {
	/* Constructor Function */
	public function new(kr : KeyRange):Void {
		range = kr;
	}

/* === Instance Methods === */

	/*
	public function includes(value : Dynamic):Bool {
		return range.includes( value );
	}
	*/

/* === Computed Instance Fields === */

	public var lower(get, never):Bool;
	private inline function get_lower():Bool return range.lower;
	
	public var lowerOpen(get, never):Bool;
	private inline function get_lowerOpen():Bool return range.lowerOpen;
	
	public var upper(get, never):Bool;
	private inline function get_upper():Bool return range.upper;
	
	public var upperOpen(get, never):Bool;
	private inline function get_upperOpen():Bool return range.upperOpen;

/* === Instance Fields === */

	public var range : KeyRange;

/* === Static Methods === */

	public static function only(v : Dynamic):IDBKeyRange return kr(KeyRange.only( v ));
	public static function upperBound(v:Dynamic, inclusive:Bool=true):IDBKeyRange return kr(KeyRange.upperBound(v, !inclusive));
	public static function lowerBound(v:Dynamic, inclusive:Bool=true):IDBKeyRange return kr(KeyRange.lowerBound(v, !inclusive));
	public static function bound(x:Dynamic, y:Dynamic, xinclusive:Bool=true, yinclusive:Bool=true):IDBKeyRange {
		return kr(KeyRange.bound(x, y, !xinclusive, !yinclusive));
	}

	private static inline function kr(r : KeyRange):IDBKeyRange return new IDBKeyRange( r );
}
