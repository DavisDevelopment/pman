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

class Application {
	/* Constrcutor Function */
	public function new():Void {
		win = Win.current;
		self = Obj.fromDynamic( this );
		var rtitle = Ptr.create( win.document.title );
		self.defineProperty('title', rtitle);
		body = new Body( this );
	}

/* === Instance Methods === */

	/**
	  * Start [this] Application
	  */
	public function start():Void {
		null;
	}

/* === Instance Fields === */

	public var title : String;
	public var win : Win;
	public var self : Obj;
	public var body : Body;
}
