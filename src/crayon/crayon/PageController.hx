package crayon;

import foundation.*;
import tannus.html.Element;
import tannus.html.Win;
import tannus.ds.*;
import tannus.io.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class PageController <T:Page> {
	/* Constructor Function */
	public function new():Void {
		page = null;

		_disabled = false;
	}

/* === Instance Methods === */

	/**
	  * when [this] gets attached to a Page
	  */
	public function attach(p : T):Void {
		page = p;
	}

	/**
	  * when [this] gets detached from a Page
	  */
	public function detach(p : T):Void {
		page = null;
	}

	/**
	  * disable [this] Controller, but not detach it. intended for use as a 'pause' type thing
	  */
	public function disable():Void {
		_disabled = true;
	}

	/**
	  * enable [this] Controller
	  --
	  * typically will do nothing unless the Controller has been previously disabled
	  */
	public function enable():Void {
		_disabled = false;
	}

	/**
	  * Check whether [this] is currently disabled
	  */
	public inline function isDisabled():Bool return _disabled;

/* === Instance Fields === */

	public var page : Null<T>;

	private var _disabled : Bool;
}
