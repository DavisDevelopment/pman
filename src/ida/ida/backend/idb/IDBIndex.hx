package ida.backend.idb;

import tannus.ds.*;
import tannus.html.Win;

import js.html.idb.*;

import ida.Utils;

using ida.Utils;

class IDBIndex {
	/* Constructor Function */
	public function new(i : Index):Void {
		this.i = i;
	}

/* === Instance Methods === */

	/**
	  * Obtain the first entry for which the value of the field referred to by [name] is [value]
	  */
	public function get(value : Dynamic):Promise<Dynamic> {
		return i.get( value ).fulfill();
	}

	/**
	  * Get the primary-key for the first entry for which the value of the field referred to by [name] is [value]
	  */
	public function getKey(value : Dynamic):Promise<Dynamic> {
		return i.getKey( value ).fulfill();
	}

	/**
	  * Open a CursorWalker
	  */
	public function openCursor(?body:IDBCursor->IDBCursorWalker->Void, ?keyRange:Dynamic, ?direction:CursorDirection):IDBCursorWalker {
		var request = i.openCursor(keyRange, untyped direction);
		if (body == null) {
			return new IDBCursorWalker( request );
		}
		else {
			return new IDBFunctionalCursorWalker(request, body);
		}
	}

/* === Computed Instance Fields === */

	public var name(get, never):String;
	private inline function get_name():String return i.name;

	public var keyPath(get, never):Dynamic;
	private inline function get_keyPath() return i.keyPath;

	public var objectStore(get, never):IDBObjectStore;
	private inline function get_objectStore():IDBObjectStore {
		return (untyped i.objectStore.__wrapper);
	}

	public var multiEntry(get, never):Bool;
	private inline function get_multiEntry():Bool return i.multiEntry;
	
	public var unique(get, never):Bool;
	private inline function get_unique():Bool return i.unique;

/* === Instance Fields === */

	public var i : Index;
}
