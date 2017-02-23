package ida;

import tannus.ds.*;

import js.html.idb.*;

import Std.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class Utils {
	/**
	  * Build a Promise from a Request
	  */
	public static function fulfill<T>(request : Request):Promise<T> {
		var r = request;
		return Promise.create({
			function success(e){
				return untyped r.result;
			}
			function error(e){
				throw r.error;
			}
			r.onsuccess = success;
			r.onerror = error;
		});
	}

	public static function report(req:Request, callback:Null<Callback>):Void {
		if (callback != null && Reflect.isFunction( callback )) {
			req.onerror = (function(e) callback( req.error ));
			req.onsuccess = (function(e) callback( null ));
		}
	}

	/**
	  * Converts an index reference into the type used by the underlying system
	  */
	public static function keyToNative(key : Dynamic):Dynamic {
		if (is(key, ida.backend.idb.IDBKeyRange)) {
			return cast(key, ida.backend.idb.IDBKeyRange).range;
		}
		else {
			return key;
		}
	}
}

typedef CreateObjectStoreOptions = {
	keyPath : String,
	?autoIncrement : Bool
};

typedef CreateIndexOptions = {
	?locale : String,
	?multiEntry : Bool,
	?unique : Bool
};

typedef Callback = Null<Dynamic> -> Void;

@:enum
abstract TransactionMode (String) from String to String {
	var Cleanup = 'cleanup';
	var ReadOnly = 'readonly';
	var ReadWrite = 'readwrite';
	var ReadWriteFlush = 'readwriteflush';
	var VersionChange = 'versionchange';
}

@:enum
abstract CursorDirection (String) from String to String {
	var Next = 'next';
	var NextUnique = 'nextunique';
	var Prev = 'prev';
	var PrevUnique = 'prevunique';
}

enum CursorSource {
	CSObjectStore(store : ida.ObjectStore);
	CSIndex(index : ida.Index);
}
