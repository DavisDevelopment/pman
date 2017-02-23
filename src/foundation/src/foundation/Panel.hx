package foundation;

import foundation.Pane;

class Panel extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();
		addClass('panel');
	}

/* === Computed Instance Fields === */

	/**
	  * Whether [this] Panel has rounded corners
	  */
	public var roundCorners(get, set):Bool;
	private function get_roundCorners() return el.is('.radius');
	private function set_roundCorners(r : Bool):Bool {
		(r?addClass:removeClass)('radius');
		return r;
	}

	/**
	  * Whether [this] Panel has rounded sides
	  */
	public var roundSides(get, set):Bool;
	private function get_roundSides() return el.is('.round');
	private function set_roundSides(r : Bool):Bool {
		(r?addClass:removeClass)('round');
		return r;
	}
}
