package ida.backend.core;

import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.io.*;

import ida.Utils;

import Std.*;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using ida.Utils;

/**
  * Base-class for a backend Database implementation
  */
class BasicDatabase {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/* create a new ObjectStore */
	public function createObjectStore(name:String, callback:Null<Dynamic>->Null<BasicObjectStore>->Void):Void {
		throw 'Not implemented';
	}

/* === Computed Instance Fields === */

	/* the name of [this] database */
	public var name(get, never):String;
	private function get_name():String return '';

	/* the names of the objectStores in [this] Database */
	public var objectStoreNames(get, never):Array<String>;
	private function get_objectStoreNames():Array<String> return [];
}
