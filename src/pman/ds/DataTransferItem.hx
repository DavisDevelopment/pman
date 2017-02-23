package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.Mime;
import tannus.html.fs.WebFile;
import tannus.html.fs.WebFSEntry;

//import js.html.DragEvent as NativeDragEvent;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

abstract DataTransferItem (NDataTransferItem) from NDataTransferItem to NDataTransferItem {
	/* Constructor Function */
	public inline function new(ndti : NDataTransferItem):Void {
		this = ndti;
	}

/* === Instance Methods === */

	@:to
	public inline function getFile():Null<WebFile> {
		return new WebFile(this.getAsFile());
	}
	@:to
	public inline function getEntry():Null<WebFSEntry> return this.webkitGetAsEntry();
	@:to
	public inline function getString():Null<String> return this.getAsString();

/* === Instance Fields === */

	public var kind(get, never):DataTransferItemKind;
	private inline function get_kind() return this.kind;

	public var type(get, never):String;
	private inline function get_type():String return this.type;

	public var mimeType(get, never):Mime;
	private inline function get_mimeType():Mime return new Mime( type );
}

typedef NDataTransferItem = {
	var kind : DataTransferItemKind;
	var type : String;

	function getAsFile():Null<js.html.File>;
	function getAsString():Null<String>;
	function webkitGetAsEntry():Null<WebFSEntry>;
}

@:enum
abstract DataTransferItemKind (String) from String to String {
	var DKString = 'string';
	var DKFile = 'file';
}
