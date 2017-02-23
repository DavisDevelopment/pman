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

class IDBFunctionalCursorWalker extends IDBCursorWalker {
	/* Constructor Function */
	public function new(r:Request, f:IDBCursor->Void):Void {
		super( r );

		body = f;
	}

/* === Instance Methods === */

	/**
	  * do the stuff
	  */
	override public function step(cursor : IDBCursor):Void {
		var next = cursor.next.bind();
		var calledNext:Bool = false;
		(untyped cursor).next = function(?key:Dynamic){
			next();
			calledNext = true;
		};
		body( cursor );
		if ( !calledNext ) {
			cursor.next();
		}
	}

/* === Instance Fields === */

	private var body : IDBCursor -> Void;
}
