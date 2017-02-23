package vex.svg;

import tannus.geom.*;

import vex.svg.SVGElement.createElement;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

@:expose( 'Line' )
class SVGLine extends SVGElement {
	/* Constructor Function */
	public function new(x1:Float=0, y1:Float=0, x2:Float=0, y2:Float=0):Void {
		super();

		e = createElement( 'line' );
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;

		o.define('x1', x1);
		o.define('x2', x2);
		o.define('y1', y1);
		o.define('y2', y2);
		o.define('one', one);
		o.define('two', two);
	}

/* === Instance Methods === */

	/**
	  * Clone [this] Line
	  */
	override public function clone():SVGElement {
		var c = new SVGLine(x1, y1, x2, y2);
		c.style.cloneFrom( style );
		return c;
	}

/* === Computed Instance Fields === */

	/* the x1 property */
	public var x1(get, set):Float;
	private inline function get_x1():Float return (hasAttribute('x1') ? parseFloat(getAttribute('x1')) : 0);
	private inline function set_x1(v : Float):Float return parseFloat(setAttribute('x1', v));

	public var y1(get, set):Float;
	private inline function get_y1():Float return (hasAttribute('y1') ? parseFloat(getAttribute('y1')) : 0);
	private inline function set_y1(v : Float):Float return parseFloat(setAttribute('y1', v));

	public var x2(get, set):Float;
	private inline function get_x2():Float return (hasAttribute('x2') ? parseFloat(getAttribute('x2')) : 0);
	private inline function set_x2(v : Float):Float return parseFloat(setAttribute('x2', v));

	public var y2(get, set):Float;
	private inline function get_y2():Float return (hasAttribute('y2') ? parseFloat(getAttribute('y2')) : 0);
	private inline function set_y2(v : Float):Float return parseFloat(setAttribute('y2', v));

	/* the starting point */
	public var one(get, set):Point;
	private inline function get_one():Point return Point.linked(x1, y1);
	private function set_one(v : Point):Point {
		x1 = v.x;
		y1 = v.y;
		return v;
	}

	/* the end point */
	public var two(get, set):Point;
	private inline function get_two():Point return Point.linked(x2, y2);
	private function set_two(v : Point):Point {
		x2 = v.x;
		y2 = v.y;
		return v;
	}
}
