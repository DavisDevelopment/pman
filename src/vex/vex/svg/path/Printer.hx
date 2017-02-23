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

class Printer {
	/* Constructor Function */
	public function new():Void {
		null;
	}

/* === Instance Methods === */

	/**
	  * print the given list of commands
	  */
	public function printCommands(list : Array<Command>):String {
		buffer = new ByteArray( 0 );
		commands = list;

		for (c in commands) {
			printCommand( c );
		}

		return buffer.toString();
	}

	/**
	  * print a single command
	  */
	private function printCommand(c : Command):Void {
		switch ( c ) {
			case CMove(pos, rel):
				tag('M', rel);
				point( pos );

			case CLine(pos, rel):
				tag('L', rel);
				point( pos );

			case CVertical(d, rel):
				tag('V', rel);
				float( d );

			case CHorizontal(d, rel):
				tag('H', rel);
				float( d );

			case CBezier(one, two, pos, rel):
				tag('C', rel);
				points([one, two, pos]);

			case CQuadratic(ctrl, pos, rel):
				tag('Q', rel);
				points([ctrl, pos]);

			case CArc(radius, angle, large, sweep, pos, rel):
				tag('A', rel);
				point( radius );
				w( ' ' );
				float( angle );
				w( ' ' );
				bool( large );
				w(' ');
				bool( sweep );
				w(' ');
				point( pos );

			case CClose:
				w( 'Z' );
		}
	}

	/* write the given letter, and lowercase it */
	private inline function tag(s:String, lower:Bool):Void {
		if ( lower )
			s = s.toLowerCase();
		w( s );
	}

	/* write the given list of Points */
	private function points(list : Array<Point>):Void {
		var last = list.pop();
		for (p in list) {
			point( p );
			w( ' ' );
		}
		point( last );
	}

	/* write the given Point */
	private inline function point(p : Point):Void {
		float( p.x );
		w(' ');
		float( p.y );
	}
	/* write the given Float */
	private inline function float(n : Float):Void w(n + '');
	private inline function bool(v : Bool):Void w(v ? '1' : '0');

	/* write the given String to [buffer] */
	private inline function w(s : String):Void {
		buffer.appendString( s );
	}

/* === Instance Fields === */

	private var buffer : ByteArray;
	private var commands : Array<Command>;

/* === Static Methods === */

	public static function print(list : Array<Command>):String {
		return new Printer().printCommands( list );
	}
}
