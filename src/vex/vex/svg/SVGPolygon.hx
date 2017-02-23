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

@:expose('Polygon')
class SVGPolygon extends SVGElement {
	/* Constructor Function */
	public function new():Void {
		super();

		e = createElement( 'polygon' );
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
	  * Get the number of Points in [this] Polygon
	  */
	public function numPoints():Int {
		return spoints.count( ',' );
	}

	/**
	  * Get the Point at the given Index
	  */
	public inline function getPoint(index : Int):Null<Point> {
		return points.get( index );
	}

	/**
	  * Set the Point at the given Index
	  */
	public inline function setPoint(index:Int, point:Point):Point {
		var l = points;
		l.set(index, point);
		points = l;
		return point.clone();
	}

	/**
	  * Create and return a clone of [this] Polygon
	  */
	override public function clone():SVGElement {
		var c = new SVGPolygon();
		c.points = points;
		c.style.cloneFrom( style );
		return c;
	}

/* === Computed Instance Fields === */

	/* the raw value of the 'points' attribute */
	public var spoints(get, set):String;
	private inline function get_spoints():String return (hasAttribute('points') ? attr('points') : '');
	private inline function set_spoints(v : String):String return attr('points', v);

	public var points(get, set):Vertices;
	private function get_points():Vertices {
		var l = spoints.split(' ').macmap(Point.fromFloatArray(_.split( ',' ).map( parseFloat )));
		trace( l );
		return new Vertices( l );
	}
	private function set_points(v : Vertices):Vertices {
		spoints = v.array().macmap(_.x + ',' + _.y).join(' ');
		return v.clone();
	}

/* === Static Function === */

	/**
	  * Create and return a Polygon from a Vertex Array
	  */
	public static function fromVertices(vertices : Vertices):SVGPolygon {
		var p = new SVGPolygon();
		p.points = vertices;
		return p;
	}

	/**
	  * Create and return a Polygon from a Polygon
	  */
	public static function fromPolygon(shape : Polygon):SVGPolygon {
		return fromVertices(shape.getVertices());
	}
}
