package vex.svg;

import tannus.geom.*;

import vex.svg.SVGElement.createElement;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

@:expose('Polyline')
class SVGPolyline extends SVGElement {
	/* Constructor Function */
	public function new():Void {
		super();

		e = createElement( 'polyline' );
	}

/* === Instance Methods === */

	/**
	  * Add a Point to [this] Polygon
	  */
	public function addPoint(p : Point):Void {
		if (hasAttribute( 'points' )) {
			var s = getAttribute( 'points' );
			s += ' ${p.x},${p.y}';
			setAttribute('points', s);
		}
		else {
			setAttribute('points', (p.x + ',' + p.y));
		}
	}

	/**
	  * Create and return a clone of [this] Polygon
	  */
	override public function clone():SVGElement {
		var c = new SVGPolyline();
		c.points = points;
		c.style.cloneFrom( style );
		return c;
	}

/* === Computed Instance Fields === */

	public var points(get, set):Vertices;
	private function get_points():Vertices {
		var s = (hasAttribute('points') ? getAttribute('points') : '');
		var l = s.split(' ').macmap(Point.fromFloatArray(_.split( ',' ).map( parseFloat )));
		trace( l );
		return new Vertices( l );
	}
	private function set_points(v : Vertices):Vertices {
		setAttribute('points', v.array().macmap(_.x + ',' + _.y).join(' '));
		return v.clone();
	}
}
