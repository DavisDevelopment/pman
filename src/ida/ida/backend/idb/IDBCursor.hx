package ida.backend.idb;

import tannus.ds.*;
import tannus.io.Signal;
import tannus.io.VoidSignal;
import tannus.html.Win;

import js.html.idb.*;
import js.html.DOMError;
import haxe.Constraints.Function;

import ida.Utils;

import Std.*;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using ida.Utils;

class IDBCursor {
	/* Constructor Function */
	public function new(c : Cursor):Void {
		cursor = c;
	}

/* === Instance Methods === */

	/**
	  * set the distance that [this] Cursor will move forward
	  */
	public function advance(n : Int):Void {
		cursor.advance( n );
	}

	/**
	  * jump ahead to the next entry, or to the next entry referred to by [key]
	  */
	public function next(?key : Dynamic):Void {
		cursor.continue_( key );
	}

	/**
	  * delete the current entry
	  */
	public function delete(callback : Null<Dynamic>->Void):Void {
		cursor.delete_().report( callback );
	}

	/**
	  * update the current entry
	  */
	public function update(entry:Dynamic, callback:Null<Dynamic>->Void):Void {
		cursor.update( entry ).report( callback );
	}

/* === Computed Instance Fields === */

	public var entry(get, never):Null<Dynamic>;
	private inline function get_entry():Null<Dynamic> {
		return (untyped cursor).value;
	}

	public var direction(get, never):CursorDirection;
	private inline function get_direction():CursorDirection return untyped cursor.direction;
	
	public var key(get, never):Dynamic;
	private inline function get_key():Dynamic return cursor.key;
	
	public var primaryKey(get, never):Dynamic;
	private inline function get_primaryKey():Dynamic return cursor.primaryKey;

	public var source(get, never):CursorSource;
	private function get_source():CursorSource {
		if (_src == null) {
			if (is(cursor.source, ObjectStore)) {
				_src = CSObjectStore(new IDBObjectStore( cursor.source ));
			}
			else if (is(cursor.source, Index)) {
				_src = CSIndex(new IDBIndex( cursor.source ));
			}
		}
		return _src;
	}

	public var objectStore(get, never):IDBObjectStore;
	private function get_objectStore():IDBObjectStore {
		switch ( source ) {
			case CSObjectStore( store ):
				return store;
			case CSIndex( index ):
				return index.objectStore;
		}
	}

	public var index(get, never):Null<IDBIndex>;
	private function get_index():Null<IDBIndex> {
		switch ( source ) {
			case CSIndex( i ):
				return i;
			default:
				return null;
		}
	}

/* === Instance Fields === */

	public var cursor : Cursor;
	
	private var _src : Null<CursorSource> = null;
}
