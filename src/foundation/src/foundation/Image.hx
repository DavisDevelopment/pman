package foundation;

import tannus.html.Element;

import js.html.Image in JsImage;

import Math.*;
import tannus.math.TMath.*;

class Image extends Widget {
	/* Constructor Function */
	public function new(?source : String):Void {
		super();

		el = '<img></img>';

		if (source != null) {
			src = source;
		}
	}

/* === Instance Fields === */

	public var image(get, never):JsImage;
	private inline function get_image():JsImage return cast el.at(0);

	public var src(get, set):String;
	private inline function get_src():String return image.src;
	private inline function set_src(v:String):String return (image.src = v);

	public var naturalWidth(get, never):Int;
	private inline function get_naturalWidth():Int return image.naturalWidth;
	
	public var naturalHeight(get, never):Int;
	private inline function get_naturalHeight():Int return image.naturalHeight;

	override private function get_width():Float return image.width;
	override private function set_width(v : Float):Float return (image.width = round( v ));

	override private function get_height():Float return image.height;
	override private function set_height(v : Float):Float return (image.height = round( v ));

	public var complete(get, never):Bool;
	private inline function get_complete():Bool return (image.complete && (src != null) && (src != ''));

	/*
	public var width(get, set):Int;
	private inline function get_width():Int return image.width;
	private inline function set_width(v : Int):Int return (image.width = v);
	public var height(get, set):Int;
	private inline function get_height():Int return image.height;
	private inline function set_height(v : Int):Int return (image.height = v);
	private inline function set_naturalWidth(v : Int):Int return (image.naturalWidth = v);
	public var naturalHeight(get, set):Int;
	private inline function get_naturalHeight():Int return image.naturalHeight;
	private inline function set_naturalHeight(v : Int):Int return (image.naturalHeight = v);
	*/
}
