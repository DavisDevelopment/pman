package vex.core;

import tannus.geom.*;

class BaseDocument extends Element {
	/* Constructor Function */
	public function new():Void {
		super();
	}

/* === Computed Instance Fields === */

	public var x(get, set):Float;
	private function get_x():Float return 0;
	private function set_x(v : Float):Float return 0;

	public var y(get, set):Float;
	private function get_y():Float return 0;
	private function set_y(v : Float):Float return 0;

	public var width(get, set):Float;
	private function get_width():Float return 0;
	private function set_width(v : Float):Float return 0;

	public var height(get, set):Float;
	private function get_height():Float return 0;
	private function set_height(v : Float):Float return 0;
}
