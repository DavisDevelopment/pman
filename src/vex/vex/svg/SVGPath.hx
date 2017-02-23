package vex.svg;

import tannus.geom.*;

import vex.svg.SVGElement.createElement;
import vex.svg.path.Command;
import vex.svg.path.*;
import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.macro.MacroTools;

@:expose( 'Path' )
class SVGPath extends SVGElement {
	/* Constructor Function */
	public function new():Void {
		super();

		e = createElement( 'path' );
	}

/* === Instance Methods === */

	/**
	  * Create and return a PathEditor bound to [this] Path
	  */
	public function edit():Editor {
		return new Editor( this );
	}

	/**
	  * Create and return a clone of [this]
	  */
	override public function clone():SVGElement {
		var c = new SVGPath();
		c.commands = commands;
		c.style.cloneFrom( style );
		return c;
	}

	/**
	  * Create a tannus.geom.Path from [this]
	  */
	public function toGeomPath():Array<Path> {
		return [];
	}

/* === Computed Instance Fields === */

	/* the raw value of the 'd' attribute */
	public var d(get, set):String;
	private inline function get_d():String return (hasAttribute('d') ? attr('d') : '');
	private inline function set_d(v : String):String return attr('d', v);

	/* the Array of Commands */
	public var commands(get, set):Array<Command>;
	private function get_commands():Array<Command> {
		return Parser.parseString( d );
	}
	private function set_commands(list : Array<Command>):Array<Command> {
		d = Printer.print( list );
		return list.copy();
	}

/* === Static Methods === */

	/**
	  * Create and return an SVGPath from a command-string
	  */
	public static function fromCommandString(s : String):SVGPath {
		var path = new SVGPath();
		path.d = s;
		return path;
	}
}
