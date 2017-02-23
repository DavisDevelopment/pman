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

class IDBCursorWalker {
	/* Constructor Function */
	public function new(r : Request):Void {
		this.r = r;
		complete = new VoidSignal();
		error = new Signal();
		
		r.addEventListener('success', __onsuccess);
	}

/* === Instance Methods === */

	/**
	  * Handles the 'success' event of [r]
	  */
	private function __onsuccess(event : Dynamic):Void {
		var _cursor:Null<Cursor> = event.target.result;
		trace( _cursor );
		if (_cursor == null) {
			complete.fire();
		}
		else {
			var cursor:IDBCursor = new IDBCursor( _cursor );
			step( cursor );
		}
	}

	/**
	  * The equivalent of the 'body' of the loop
	  */
	public function step(cursor : IDBCursor):Void {
		null;
	}

/* === Instance Fields === */

	public var complete : VoidSignal;
	public var error : Signal<Dynamic>;

	private var r : Request;
}
