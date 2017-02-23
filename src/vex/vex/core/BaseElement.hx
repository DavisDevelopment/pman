package vex.core;

import tannus.ds.Memory;

class BaseElement {
	/* Constructor Function */
	public function new():Void {
		id = Memory.allocRandomId( 6 );
	}

/* === Instance Methods === */

	/**
	  * Append [this] to the given Node
	  */
	public function appendTo(parent : js.html.Element):Void {
		null;
	}

	/**
	  * Append the given Element to [this] one
	  */
	public function append(child : Element):Void {
		null;
	}

	/**
	  * Remove [this] Element from the Document
	  */
	public function remove():Void {
		null;
	}

	/**
	  * Remove the given Element from [this] one
	  */
	public function removeElement(child : Element):Bool {
		return true;
	}

	/**
	  * Check whether [this] Element is the parent of the given Element
	  */
	public function hasChild(child : Element):Bool {
		return true;
	}

	/**
	  * get/set attributes of [this] Element
	  */
	public function attr(name:String, ?value:Dynamic):String {
		if (value == null) {
			return getAttribute( name );
		}
		else {
			return setAttribute(name, value);
		}
	}

	/**
	  * get the value of an attribute
	  */
	public function getAttribute(key : String):String {
		return '';
	}

	/**
	  * set the value of an attribute
	  */
	public function setAttribute(name:String, value:Dynamic):String {
		return Std.string( value );
	}

	/**
	  * remove an attribute from [this] Element
	  */
	public function removeAttribute(name : String):Bool {
		return false;
	}

	public function hasAttribute(name : String):Bool {
		return false;
	}

/* === Instance Fields ==== */

	public var id : String;
}
