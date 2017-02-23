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

class Editor {
	/* Constructor Function */
	public function new(p : SVGPath):Void {
		path = p;
		commands = path.commands;
	}

/* === Instance Methods === */

	/* clear [this] Path */
	public function clear():Void {
		commands = new Array();
	}

	/* move to the given point */
	public function moveToPoint(p : Point):Void {
		cmd(CMove(p, false));
	}

	/* move to the given coordinates */
	public function moveTo(x:Float, y:Float):Void {
		moveToPoint(new Point(x, y));
	}

	/* relative move */
	public function movePoint(p : Point):Void {
		cmd(CMove(p, true));
	}
	public function move(x:Float, y:Float):Void movePoint(new Point(x, y));

	/* line to the given Point */
	public function lineToPoint(p : Point):Void {
		cmd(CLine(p, false));
	}
	public function lineTo(x:Float, y:Float):Void {
		lineToPoint(new Point(x, y));
	}

	/* relative line */
	public function linePoint(p : Point):Void {
		cmd(CLine(p, true));
	}
	public function line(x:Float, y:Float):Void {
		linePoint(new Point(x, y));
	}

	/* vertical line */
	public function vertical(to_y : Int):Void {
		cmd(CVertical(to_y, false));
	}
	public function horizontal(to_x : Int):Void {
		cmd(CHorizontal(to_x, false));
	}

	public function up(d : Int):Void cmd(CVertical(-d, true));
	public function down(d : Int):Void cmd(CVertical(d, true));
	public function right(d : Int):Void cmd(CHorizontal(d, true));
	public function left(d : Int):Void right( -d );

	public function addBezier(b:Bezier, relative:Bool=false):Void {
		cmd(CBezier(b.ctrl1, b.ctrl2, b.end, relative));
	}

	public function bezier(c1x:Float, c1y:Float, c2x:Float, c2y:Float, x:Float, y:Float, relative:Bool=false):Void {
		var b = new Bezier(new Point(), new Point(c1x, c1y), new Point(c2x, c2y), new Point(x, y));
		addBezier( b );
	}

	public function addEllipticalArc(goal:Point, radius:Point, angle:Float, large:Bool=false, sweep:Bool=false, relative:Bool=false):Void {
		cmd(CArc(radius, angle, large, sweep, goal, relative));
	}

	public function earc(tox:Float, toy:Float, radx:Float, rady:Float, angle:Float, large:Bool=false, sweep:Bool=false, relative:Bool=false):Void {
		addEllipticalArc(
			new Point(tox, toy),
			new Point(radx, rady),
			angle, large, sweep, relative
		);
	}

	public function addArc(center:Point, radius:Float, startAngle:Angle, endAngle:Angle):Void {
		var x1:Float = (center.x + (radius * cos( -startAngle.radians )));
		var y1:Float = (center.y + (radius * sin( -startAngle.radians )));
		var x2:Float = (center.x + (radius * cos( -endAngle.radians )));
		var y2:Float = (center.y + (radius * sin( -endAngle.radians )));
		moveTo(x1, y1);
		earc(x2, y2, radius, radius, endAngle.degrees, (endAngle.degrees - startAngle.degrees > 180), false, false);
	}

	public function arc(cx:Float, cy:Float, r:Float, start:Float, end:Float):Void {
		addArc(new Point(cx, cy), r, start, end);
	}

	public function addWedge(center:Point, radius:Float, startAngle:Angle, endAngle:Angle):Void {
		var x1:Float = (center.x + (radius * cos( -startAngle.radians )));
		var y1:Float = (center.y + (radius * sin( -startAngle.radians )));
		var x2:Float = (center.x + (radius * cos( -endAngle.radians )));
		var y2:Float = (center.y + (radius * sin( -endAngle.radians )));
		moveToPoint( center );
		lineTo(x1, y1);
		earc(x2, y2, radius, radius, endAngle.degrees, (endAngle.degrees - startAngle.degrees > 180), false, false);
		lineToPoint( center );
	}

	public function wedge(cx:Float, cy:Float, r:Float, start:Float, end:Float):Void {
		addWedge(new Point(cx, cy), r, start, end);
	}

	public function close():Void {
		cmd( CClose );
	}

	public function save():Void {
		path.commands = commands;
	}

	public function undo():Void {
		commands.pop();
	}

	/* add the given Command to the stack */
	private inline function cmd(c : Command):Void {
		commands.push( c );
	}

/* === Instance Fields === */

	public var path : SVGPath;
	private var commands : Array<Command>;
}
