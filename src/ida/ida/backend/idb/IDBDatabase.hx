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
	/**
	  * Create and return a new Transaction object
	  */
	public function transaction(stores:Either<String, Array<String>>, ?mode:TransactionMode):IDBTransaction {
		if (mode == null) mode = ReadOnly;
		return new IDBTransaction(db.transaction(stores, untyped mode));
	}

	/**
	  * Create and return a new MutableFile
	  */
	/*
	public function createMutableFile(name:String, ?type:String):Promise<Dynamic> {
		db.createMutableFile(name, type).fulfill();
	}
	*/

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
