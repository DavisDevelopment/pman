package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

/**
  * class that represents an ipc-address
  */
class IpcAddress {
	/* Constructor Function */
	public function new(id:String, type:IpcAddressType):Void {
		this.id = id;
		this.type = type;
	}

/* === Instance Methods === */

	/**
	  * create and return a deep-copy of [this]
	  */
	public function clone():IpcAddress {
		return new IpcAddress(
			this.id,
			this.type
		);
	}

	// serialize [this]
	@:keep
	public function hxSerialize(s : Serializer):Void {
		var w = s.serialize;

		w( id );
		w( type );
	}

	// unserialize [this]
	@:keep
	public function hxUnserialize(u : Unserializer):Void {
		var r = u.unserialize;

		id = r();
		type = r();
	}

/* === Instance Fields === */

	public var id : String;
	public var type : IpcAddressType;
}
