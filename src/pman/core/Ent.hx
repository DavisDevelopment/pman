package pman.core;

import gryffin.core.*;
import gryffin.display.*;

import tannus.geom2.*;

class Ent extends EntityContainer {
	/* Constructor Function */
	public function new():Void {
		super();

		rect = new Rect();
	}

/* === Instance Methods === */

	/**
	  * Check whether the given Point is 'inside' [rect]
	  */
	override public function containsPoint(p : Point<Float>):Bool {
		return (rect.containsPoint( p ));
	}

	/**
	  * update [this] Ent
	  */
	override public function update(stage : Stage):Void {
		super.update( stage );
	}

	/**
	  *
	  */

/* === Computed Instance Fields === */

	/* the 'x' position of [this] */
	public var x(get, set):Float;
	private inline function get_x():Float return rect.x;
	private inline function set_x(v : Float):Float return (rect.x = v);
	
	/* the 'y' position of [this] */
	public var y(get, set):Float;
	private inline function get_y():Float return rect.y;
	private inline function set_y(v : Float):Float return (rect.y = v);
	
	/* the width of [this] */
	public var w(get, set):Float;
	private function get_w():Float return rect.w;
	private function set_w(v : Float):Float return (rect.w = v);
	
	/* the height of [this] */
	public var h(get, set):Float;
	private function get_h():Float return rect.h;
	private function set_h(v : Float):Float return (rect.h = v);

	/* the position of [this], as a Point */
	public var pos(get, set):Point<Float>;
	@:deprecated
	private function get_pos():Point<Float> return new Point(rect.x, rect.y);
	private function set_pos(v : Point<Float>) {
		return new Point(x=v.x, y=v.y);
	}

	/* the center of [this] along the x-axis */
	public var centerX(get, set):Float;
	private function get_centerX():Float {
		return (x + (w / 2));
	}
	private function set_centerX(v : Float):Float {
		return (x = (v - (w / 2)));
	}

	/* the center of [this] along the y-axis */
	public var centerY(get, set):Float;
	private function get_centerY():Float {
		return (y + (h / 2));
	}
	private function set_centerY(v : Float):Float {
		return (y = (v - (h / 2)));
	}

	/* the center of [this] */
	public var center(get, set):Point<Float>;
	@:deprecated
	private function get_center() return new Point(centerX, centerY);
	private function set_center(v : Point<Float>):Point<Float> {
	    return new Point(centerX = v.x, centerY = v.y);
	} 

/* === Instance Fields === */

	public var rect : Rect<Float>;
	
	/* whether [this] Ent currently contains the mouse cursor */
	private var _cc : Bool = false;
}
