package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.Mime;
import tannus.html.fs.WebFile;
import tannus.html.fs.WebFSEntry;

import haxe.extern.EitherType;
//import js.html.DragEvent as NativeDragEvent;
import pman.ds.DataTransferItem;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using Lambda;
using Slambda;

abstract DataTransferItemList (NDataTransferItemList) from NDataTransferItemList to NDataTransferItemList {
	public inline function new(list : NDataTransferItemList):Void {
		this = list;
	}

/* === Instance Methods === */

	public inline function add(data:String, type:String):DataTransferItem {
		return new DataTransferItem(this.add(data, type));
	}
	public inline function addFile(file : WebFile):DataTransferItem {
		return new DataTransferItem(this.add(file.getNativeFile()));
	}
	public inline function remove(index : Int):Void this.remove( index );
	public inline function clear():Void this.clear();

	@:arrayAccess
	public inline function get(index : Int):Null<DataTransferItem> {
		return new DataTransferItem(this[index]);
	}

	public function iterator():Iterator<DataTransferItem> {
		return ((0...length).map.fn(get( _ )));
	}

/* === Instance Fields === */

	public var length(get, never):Int;
	private inline function get_length():Int return this.length;
}

extern class NDataTransferItemList implements ArrayAccess<NDataTransferItem> {
	@:overload(function(file : js.html.File):NDataTransferItem {})
	public function add(data:String, type:String):NDataTransferItem;
	public function remove(index : Int):Void;
	public function clear():Void;

	public var length(default, null):Int;
}
