package vex.svg;

import tannus.geom.*;

import vex.svg.SVGElement.createElement;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.macro.MacroTools;

@:expose( 'Rect' )
class SVGRect extends SVGElement {
	/* Constructor Function */
	public function new(x:Float=0, y:Float=0, w:Float=0, h:Float=0):Void {
		super();

		e = createElement( 'rect' );

		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
	}

/* === Instance Fields === */

	/**
	  * Convert to a Polygon
	  */
	public function toPolygon():SVGPolygon {
		var p = new SVGPolygon();
		var r = new Rectangle(x, y, width, height);
		for (pt in r.getVertices()) {
			p.addPoint( pt );
		}
		return p;
	}

	/**
	  * Create and return a clone of [this] Rect
	  */
	override public function clone():SVGElement {
		var c = new SVGRect(x, y, width, height);
		c.style.cloneFrom( style );
		return c;
	}

/* === Computed Instance Fields === */

	public var x(get, set):Float;
	private inline function get_x():Float return (hasAttribute('x') ? parseFloat(getAttribute('x')) : 0);
	private inline function set_x(v : Float):Float return parseFloat(setAttribute('x', v));

	public var y(get, set):Float;
	private inline function get_y():Float return (hasAttribute('y') ? parseFloat(getAttribute('y')) : 0);
	private inline function set_y(v : Float):Float return parseFloat(setAttribute('y', v));

	public var width(get, set):Float;
	private inline function get_width():Float return (hasAttribute('width') ? parseFloat(getAttribute('width')) : 0);
	private inline function set_width(v : Float):Float return parseFloat(setAttribute('width', v));

	public var height(get, set):Float;
	private inline function get_height():Float return (hasAttribute('height') ? parseFloat(getAttribute('height')) : 0);
	private inline function set_height(v : Float):Float return parseFloat(setAttribute('height', v));
}
