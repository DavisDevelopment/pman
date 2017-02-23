package vex.svg;

import tannus.ds.Memory;
import tannus.ds.Obj;

import vex.core.*;

import js.html.svg.Element in NativeElement;

import Std.*;

using Lambda;
using tannus.ds.ArrayTools;

class SVGElement extends BaseElement {
	/* Constructor Function */
	public function new():Void {
		super();

		_children = new Array();
		o = Obj.fromDynamic( this );
		style = new SVGStyle( this );
	}

/* === Instance Methods === */

	/**
	  * Append [this] to the given Node
	  */
	override public function appendTo(parent : js.html.Element):Void {
		parent.appendChild(cast e);
	}

	/**
	  * Append the given Element to [this] one
	  */
	override public function append(child : Element):Void {
		if (is(child, SVGElement)) {
			e.appendChild(cast(child, SVGElement).e);
			_children.push( child );
		}
		else {
			super.append( child );
		}
	}

	/**
	  * Remove the given Element from [this] one
	  */
	override public function removeElement(child : Element):Bool {
		if (is(child, SVGElement)) {
			var had = hasChild( child );
			e.removeChild( child.e );
			return had;
		}
		else {
			return super.removeElement( child );
		}
	}

	/**
	  * Remove [this] Element from the Document
	  */
	override public function remove():Void {
		e.remove();
	}

	/**
	  * Check whether [this] Element is the parent of the given one
	  */
	override public function hasChild(child : Element):Bool {
		return _children.has( child );
	}

	/**
	  * get the value of an attribute
	  */
	override public function getAttribute(name : String):String {
		return e.getAttribute( name );
	}

	/**
	  * set the value of an attribute
	  */
	override public function setAttribute(name:String, value:Dynamic):String {
		e.setAttribute(name, string( value ));
		return getAttribute( name );
	}

	/**
	  * remove an attribute from [this] Element
	  */
	override public function removeAttribute(name : String):Bool {
		var had = e.hasAttribute( name );
		e.removeAttribute( name );
		return had;
	}

	/**
	  * check for the existence of an attribute
	  */
	override public function hasAttribute(name : String):Bool {
		return e.hasAttribute( name );
	}

	/**
	  * Add an Event listener to [this]
	  */
	public function addEventListener<T>(name:String, handler:T->Void, ?transformer:Dynamic->T):Void {
		e.addEventListener(name, function(event : Dynamic) {
			if (transformer != null) {
				event = transformer( event );
			}
			handler(untyped event);
		});
	}

	/**
	  * Remove an Event listener from [this]
	  */
	public function removeEventListener<T>(name:String, handler:T->Void):Void {
		e.removeEventListener(name, handler);
	}

	/**
	  * create and return a clone of [this] Element
	  */
	public function clone():SVGElement {
		var c = new SVGElement();
		if (e != null) {
			c.e = cast e.cloneNode();
			c.style.cloneFrom( style );
		}
		return c;
	}

	/**
	  * Convert [this] to a String
	  */
	public function toString():String {
		return e.outerHTML;
	}

	/**
	  * Convert [this] to an Xml Object
	  */
	public function toXml():tannus.xml.Elem {
		return tannus.xml.Elem.parse(toString());
	}

	/**
	  * [pretty]print [this] Element
	  */
	public function print(pretty : Bool = false):String {
		var s = '<?xml version="1.0" encoding="utf-8"?>';
		if ( pretty )
			s += '\n';
		s += '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">';
		if ( pretty )
			s += '\n';
		s += toXml().print( pretty );
		return s;
	}

/* === Computed Instance Fields === */

/* === Instance Fields === */

	/* the underlying SVG Element */
	private var e : NativeElement;

	/* the children of [this] */
	private var _children : Array<Element>;

	/* [this] as an Obj */
	private var o : Obj;

	/* the Styles of [this] Element */
	public var style : SVGStyle;

/* === Static Methods === */

	/**
	  * Create and return a NativeElement of the given type
	  */
	public static inline function createElement(type : String):NativeElement {
		return cast js.Browser.document.createElementNS('http://www.w3.org/2000/svg', type);
	}
}
