package ida.backend.idb;

import tannus.ds.*;
import tannus.html.Win;
import tannus.html.fs.*;

import js.html.idb.*;
import haxe.extern.EitherType in Either;

import ida.Utils;

using Lambda;

class IDBDatabase {
	/* Constructor Function */
	public function new(d : Database):Void {
		db = d;
	}

/* === Instance Methods === */

	/**
	  * Create and return a new ObjectStore
	  */
	public function createObjectStore(name:String, ?options:CreateObjectStoreOptions) {
		var _store = db.createObjectStore(name, options);
		return new IDBObjectStore( _store );
	}

	public inline function deleteObjectStore(name : String):Void {
	    db.deleteObjectStore( name );
	}

	public function hasObjectStore(name : String):Bool {
	    return objectStoreNames.has( name );
	}

	/**
	  * Create and return a new Transaction object
	  */
	public function transaction(stores:Either<String, Array<String>>, ?mode:TransactionMode):IDBTransaction {
		if (mode == null) mode = ReadOnly;
		return new IDBTransaction(db.transaction(stores, untyped mode));
	}

	/**
	  * close [this] database
	  */
	public inline function close():Void {
	    db.close();
	}

/* === Computed Instance Fields === */

    public var version(get, never):Int;
    private inline function get_version():Int return db.version;

    public var objectStoreNames(get, never):Array<String>;
    private function get_objectStoreNames():Array<String> {
        return (untyped (untyped __js__('Array.prototype.slice.call')(db.objectStoreNames, 0)));
    }

/* === Instance Fields === */

	public var db : Database;

/* === Static Methods === */

	/**
	  * Attempt to open a database by name
	  */
	public static function open(name:String, version:Int, ?_build:IDBDatabase->Void):Promise<IDBDatabase> {
		var w = Win.current;
		return Promise.create({
			var request = w.indexedDB.open(name, version);
			request.onupgradeneeded = function(event) {
				if (_build != null) {
					var db = new IDBDatabase( event.target.result );
					_build( db );
					@forward open(name, version);
				}
			};
			request.onsuccess = function(event:Dynamic) {
				var _db:Database = event.target.result;
				return new IDBDatabase( _db );
			};
			request.onerror = function(event:Dynamic) {
				throw event.target.errorCode;
			};
		});
	}
}
