package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;

import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class SearchEngine<T> {
	/* Constructor Function */
	public function new():Void {
		context = new Array();
	}

/* === Instance Methods === */

	/**
	  * get the String value of the given context item
	  */
	private function getValue(item : T):String {
		return '';
	}

/* === Instance Fields === */

	public var context : Array<T>;
}
