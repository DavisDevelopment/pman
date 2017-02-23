package vex.svg;

import tannus.ds.Memory;
import tannus.ds.Obj;

import vex.core.*;

import js.html.svg.Element in NativeElement;

import Std.*;
import Math.*;
import tannus.math.TMath;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class SVGStyle {
	/* Constructor Function */
	public function new(element : Element):Void {
		e = element;

		jsify();
	}

/* === Instance Methods === */

	/**
	  * Expose the fields of [this] object in a js-friendly way
	  */
	private inline function jsify():Void {
		var o:Obj = this;

		o.define('stroke', stroke);
		o.define('strokeWidth', strokeWidth);
		o.define('fill', fill);
	}

	/**
	  * Copy the data from [src] onto [this]
	  */
	public function cloneFrom(src : SVGStyle):Void {
		stroke = src.stroke;
		strokeWidth = src.strokeWidth;
		fill = src.fill;
	}

/* === Computed Instance Fields === */

	/* the stroke color of [this] Element */
	public var stroke(get, set):Null<String>;
	private inline function get_stroke():Null<String> return (e.hasAttribute('stroke') ? e.getAttribute('stroke') : null);
	private function set_stroke(v : Null<String>):Null<String> {
		if (v == null) v = 'none';
		return e.setAttribute('stroke', v);
	}

	public var fill(get, set):Null<String>;
	private inline function get_fill():Null<String> return (e.hasAttribute('fill') ? e.getAttribute('fill') : null);
	private function set_fill(v : Null<String>):Null<String> {
		if (v == null) v = 'none';
		return e.setAttribute('fill', v);
	}

	public var fillOpacity(get, set):Float;
	private inline function get_fillOpacity():Float return (e.hasAttribute('fill-opacity') ? parseFloat(e.attr('fill-opacity')) : 1);
	private inline function set_fillOpacity(v : Float):Float return parseFloat(e.attr('fill-opacity', v));

	public var strokeWidth(get, set):Float;
	private inline function get_strokeWidth():Float return (e.hasAttribute('stroke-width') ? parseFloat(e.getAttribute('stroke-width')) : 1);
	private inline function set_strokeWidth(v : Float):Float return parseFloat(e.attr('stroke-width', v));

	public var lineJoin(get, set):Null<String>;
	private inline function get_lineJoin():Null<String> return (e.hasAttribute('stroke-linejoin') ? e.attr('stroke-linejoin') : null);
	private inline function set_lineJoin(v : Null<String>):Null<String> {
		return e.attr('stroke-linejoin', v);
	}

/* === Instance Fields === */

	private var e : Element;
}
