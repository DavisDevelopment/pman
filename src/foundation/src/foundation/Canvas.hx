package foundation;

import tannus.html.Element;

import js.html.Image in JsImage;

import gryffin.display.Canvas in Can;

import Math.*;
import tannus.math.TMath.*;

@:access( gryffin.display.Canvas )
class Canvas extends Widget {
	/* Constructor Function */
	public function new(?c : Can):Void {
		super();

		if (c == null) {
			c = Can.create(0, 0);
		}
		canvas = c;

		el = new Element( canvas.canvas );	
	}

/* === Instance Fields === */

	public var canvas(default, null):Can;
}
