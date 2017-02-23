package vex.svg;

import tannus.geom.*;
import tannus.io.*;

#if gryffin
import gryffin.display.Image;
#end

import vex.svg.SVGElement.createElement;

import js.html.svg.SVGElement in NativeDocument;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

class SVGDocument extends vex.core.BaseDocument {
	/* Constructor Function */
	public function new():Void {
		super();
		
		e = createElement( 'svg' );
		attr('xmlns', "http://www.w3.org/2000/svg");
		attr('xmlns:xlink', "http://www.w3.org/1999/xlink");
		attr('version', '1.1');
	}

/* === Instance Methods === */

	/**
	  * Convert [this] into a Blob
	  */
	public function toBlob():Blob {
		return new Blob('image.svg', 'image/svg+xml', ByteArray.ofString(print( true )));
	}

#if gryffin
	/**
	  * Convert [this] into a gryffin.display.Image
	  */
	public function toImage():Image {
		var blob = toBlob();
		return Image.load(blob.toObjectURL());
	}
#end

/* === Computed Instance Fields === */

	override private function get_x():Float return (hasAttribute('x') ? parseFloat(getAttribute('x')) : 0);
	override private function set_x(v : Float):Float return parseFloat(setAttribute('x', v));

	override private function get_y():Float return (hasAttribute('y') ? parseFloat(getAttribute('y')) : 0);
	override private function set_y(v : Float):Float return parseFloat(setAttribute('y', v));

	override private function get_width():Float return (hasAttribute('width') ? parseFloat(getAttribute('width')) : 0);
	override private function set_width(v : Float):Float return parseFloat(setAttribute('width', v));

	override private function get_height():Float return (hasAttribute('height') ? parseFloat(getAttribute('height')) : 0);
	override private function set_height(v : Float):Float return parseFloat(setAttribute('height', v));

	public var viewBox(get, set):Rectangle;
	private function get_viewBox():Rectangle {
		if (hasAttribute('viewBox')) {
			var nums = getAttribute('viewBox').replace(',', ' ').split(' ').macfilter(!_.trim().empty()).map( parseFloat );
			return Rectangle.fromArray( nums );
		}
		else {
			return new Rectangle(x, y, width, height);
		}
	}
	private function set_viewBox(v : Rectangle):Rectangle {
		setAttribute('viewBox', [v.x, v.y, v.w, v.h].map( string ).join(','));
		return v.clone();
	}

	/* [e] as an SVGDocument */
	private var svg(get, never):NativeDocument;
	private inline function get_svg():NativeDocument return cast e;
}
