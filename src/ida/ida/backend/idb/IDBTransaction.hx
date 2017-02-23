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

class IDBTransaction {
	/* Constructor Function */
	public function new(t_ : Transaction):Void {
		t = t_;

		complete = new VoidSignal();
		fail = new Signal();
		
		t.addEventListener('complete', complete.fire.bind());
		t.addEventListener('error', function(event) {
			trace( event );
			fail.call( t.error );
		});
	}

/* === Instance Methods === */

	/**
	  * Open an ObjectStore via [this] Transaction
	  */
	public function objectStore(name : String):IDBObjectStore {
		return new IDBObjectStore(t.objectStore( name ));
	}

	/**
	  * abort [this] Transaction
	  */
	public function abort():Void {
		t.abort();
	}

/* === Computed Instance Fields === */

	public var db(get, never):IDBDatabase;
	private inline function get_db():IDBDatabase return new IDBDatabase( t.db );

	public var error(get, never):Null<DOMError>;
	private inline function get_error():Null<DOMError> return t.error;

	public var mode(get, never):TransactionMode;
	private inline function get_mode():TransactionMode return untyped t.mode;

	public var objectStoreNames(get, never):Array<String>;
	private inline function get_objectStoreNames():Array<String> {
		return t.objectStoreNames.arrayify();
	}

	public var onabort(get,set):Function;
	private inline function get_onabort():Function return t.onabort;
	private inline function set_onabort(v:Function):Function return (t.onabort = v);
	
	public var oncomplete(get,set):Function;
	private inline function get_oncomplete():Function return t.oncomplete;
	private inline function set_oncomplete(v:Function):Function return (t.oncomplete = v);
	
	public var onerror(get,set):Function;
	private inline function get_onerror():Function return t.onerror;
	private inline function set_onerror(v:Function):Function return (t.onerror = v);

/* === Instance Fields === */

	public var t : Transaction;
	public var complete : VoidSignal;
	public var fail : Signal<DOMError>;
}
