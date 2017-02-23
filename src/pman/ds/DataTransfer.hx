package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.Mime;
import tannus.html.fs.WebFile;
import tannus.html.fs.WebFileList;
import tannus.html.fs.WebFSEntry;

import haxe.extern.EitherType;
//import js.html.DragEvent as NativeDragEvent;
import pman.ds.DataTransferItem;
import pman.ds.DataTransferItemList;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using Lambda;
using Slambda;

abstract DataTransfer (NDataTransfer) from NDataTransfer to NDataTransfer {
	/* Constructor Function */
	public inline function new(dt : NDataTransfer):Void {
		this = dt;
	}

	public var items(get, never):Null<DataTransferItemList>;
	private inline function get_items():Null<DataTransferItemList> {
		return (this.items != null ? new DataTransferItemList( this.items ) : null);
	}

	public var files(get, never):Null<WebFileList>;
	private inline function get_files():Null<WebFileList> {
		return (this.files != null ? new WebFileList( this.files ) : null);
	}
}

extern class NDataTransfer {
	public var items : Null<NDataTransferItemList>;
	public var files : js.html.FileList;
}
