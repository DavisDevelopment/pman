package vex.svg.path;

import tannus.geom.*;
import tannus.io.LexerBase;
import tannus.io.Byte;
import tannus.io.ByteArray;
import tannus.io.ByteStack;

import vex.svg.path.Command;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.macro.MacroTools;

@:expose( 'PathParser' )
class Parser extends LexerBase {
	/* Constructor Function */
	public function new():Void {
		commands = new Array();
	}

/* === Instance Methods === */

	/**
	  * Parse the given shit
	  */
	public function parse(data : ByteArray):Array<Command> {
		buffer = new ByteStack( data );
		commands = new Array();

		while ( !done ) {
			commands.push(parseCommand());
		}

		return commands;
	}

	/**
	  * Parse the next available command
	  */
	private function parseCommand():Command {
		var c = next();

		if (c.isWhiteSpace()) {
			advance();
			return parseCommand();
		}

		/* == Close Path == */
		else if (c == 'Z'.code) {
			advance();
			return CClose;
		}

		/* == Move == */
		else if (c == 'M'.code || c == 'm'.code) {
			var rel:Bool = (c == 'm'.code);
			advance();
			var p = new Point(readInt(), readInt());
			return CMove(p, rel);
		}

		/* == Line == */
		else if (c == 'L'.code || c == 'l'.code) {
			var rel:Bool = (c == 'l'.code);
			advance();
			var p = new Point(readInt(), readInt());
			return CLine(p, rel);
		}

		/* == Vertical Line == */
		else if (c == 'V'.code || c == 'v'.code) {
			var rel:Bool = (c == 'v'.code);
			advance();
			return CVertical(readInt(), rel);
		}

		/* == Horizontal Line == */
		else if (c == 'H'.code || c == 'h'.code) {
			var rel:Bool = (c == 'h'.code);
			advance();
			return CHorizontal(readInt(), rel);
		}

		/* == Bezier == */
		else if (c == 'C'.code || c == 'c'.code) {
			var rel:Bool = (c == 'c'.code);
			advance();
			var ctrl1 = readPoint();
			var ctrl2 = readPoint();
			var p = readPoint();
			return CBezier(ctrl1, ctrl2, p, rel);
		}

		/* == Quadratic == */
		else if (c == 'Q'.code || c == 'q'.code) {
			var rel:Bool = (c == 'q'.code);
			advance();
			var ctrl = readPoint();
			var p = readPoint();
			return CQuadratic(ctrl, p, rel);
		}

		/* == Arc == */
		else if (c == 'A'.code || c == 'a'.code) {
			var rel:Bool = (c == 'a'.code);
			advance();
			var radius = readPoint();
			var angle = readFloat();
			var large = readBool();
			var sweep = readBool();
			var p = readPoint();
			return CArc(radius, angle, large, sweep, p, rel);
		}
		
		else {
			advance();
			return parseCommand();
		}
	}

	/**
	  * Get the next Int
	  */
	private function readInt():Int {
		var s:String = '';
		while (!done && !next().isNumeric()) {
			advance();
		}
		while (!done && next().isNumeric()) {
			s += advance();
		}
		return parseInt( s );
	}

	/**
	  * get the next Float
	  */
	private function readFloat():Float {
		var s:String = '';
		while (!done && !next().isNumeric())
			advance();
		while (!done && (next().isNumeric() || next().equalsChar('.'))) {
			s += advance();
		}
		trace( s );
		return parseFloat( s );
	}

	/**
	  * Read the next Point
	  */
	private inline function readPoint():Point {
		return new Point(readFloat(), readFloat());
	}

	/**
	  * Read the next Boolean
	  */
	private inline function readBool():Bool {
		return (readInt() == 1);
	}

/* === Instance Fields === */

	public var commands : Array<Command>;

/* === Static Methods === */

	/**
	  * Shorthand to parse a String
	  */
	public static function parseString(s : String):Array<Command> {
		if (s.empty()) {
			return new Array();
		}
		else {
			return new Parser().parse(ByteArray.ofString( s ));
		}
	}
}
