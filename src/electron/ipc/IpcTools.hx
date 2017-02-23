package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import electron.ipc.IpcBusPacket;
import electron.ipc.IpcAddressType;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class IpcTools {
/* === Static Extension Methods === */

/* === Global Methods === */

	/**
	  * raise the 'not implemented' error
	  */
	public static macro function ni() {
		return macro throw 'Not implemented!';
	}

	/**
	  * shorthand to serialize a value
	  */
	public static function serialize<T>(value : T):String {
		var s:Serializer = new Serializer();
		s.useCache = s.useEnumIndex = true;
		s.serialize( value );
		return s.toString();
	}

	/**
	  * shorthand to unserialize a value
	  */
	public static inline function unserialize(data : String):Dynamic {
		return Unserializer.run( data );
	}
}
