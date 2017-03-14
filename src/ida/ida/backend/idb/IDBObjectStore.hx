package ida.backend.idb;

import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.html.Win;

import js.html.idb.*;

import ida.Utils;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using ida.Utils;

class IDBObjectStore {
	/* Constructor Function */
	public function new(o : ObjectStore):Void {
		store = o;
		(untyped store).__wrapper = this;
	}

/* === Instance Methods === */

	/**
	  * add a new index (column) to [this]
	  */
	public function createIndex(name:String, keyPath:String, ?options:CreateIndexOptions):IDBIndex {
		var index = store.createIndex(name, keyPath, untyped options);
		return new IDBIndex( index );
	}

	/**
	  * delete an index
	  */
	public function deleteIndex(indexName : String):Void {
		store.deleteIndex( indexName );
	}

	/**
	  * get an Index by name
	  */
	public function index(name : String):IDBIndex {
		return new IDBIndex(store.index( name ));
	}

	/**
	  * Add data to [this]
	  */
	public function add(entry:Dynamic, ?key:Dynamic):Promise<Dynamic> {
		return store.add(entry, key).fulfill();
	}

	/**
	  * Add (or update) an entry
	  */
	public function put(entry:Dynamic, ?key:Dynamic):Promise<Dynamic> {
		return store.put(entry, key).fulfill();
	}

	/**
	  * Delete an entry entirely
	  */
	public function delete(key:Dynamic, ?callback:Callback):Void {
		store.delete_(key.keyToNative()).report( callback );
	}

	/**
	  * Get an entry by its key
	  */
	public function get(key : Dynamic):Promise<Dynamic> {
		return store.get(key.keyToNative()).fulfill();
	}

	/**
	  * Get the primary keys for all entries
	  */
	public function getAll(?query:Dynamic, ?count:Int):ArrayPromise<Dynamic> {
		if (query != null)
			query = query.keyToNative();
		return cast((untyped store).getAll(query, count), Request).fulfill().array();
	}

	/**
	  * Create a Cursor Walker
	  */
	public function openCursor(?body:IDBCursor->IDBCursorWalker->Void, ?keyRange:Dynamic, ?direction:CursorDirection):IDBCursorWalker {
		var request = store.openCursor(keyRange, untyped direction);
		if (body != null) {
			return new IDBFunctionalCursorWalker(request, body);
		}
		else {
			return new IDBCursorWalker( request );
		}
	}

/* === Computed Instance Fields === */

	public var autoIncrement(get, never):Bool;
	private inline function get_autoIncrement():Bool return store.autoIncrement;

	public var indexNames(get, never):Array<String>;
	private inline function get_indexNames():Array<String> return store.indexNames.arrayify();

	public var keyPath(get, never):Dynamic;
	private inline function get_keyPath():Dynamic return store.keyPath;

	public var transaction(get, never):IDBTransaction;
	private inline function get_transaction():IDBTransaction return new IDBTransaction( store.transaction );

	public var name(get, never):String;
	private inline function get_name():String return store.name;

/* === Instance Fields === */

	public var store : ObjectStore;
}
