package vex.svg.path;

import tannus.geom.*;

enum Command {
	CMove(p:Point, relative:Bool);
	CLine(p:Point, relative:Bool);
	CVertical(d:Int, relative:Bool);
	CHorizontal(d:Int, relative:Bool);
	CBezier(ctrl1:Point, ctrl2:Point, p:Point, relative:Bool);
	CQuadratic(ctrl:Point, p:Point, relative:Bool);
	CArc(radius:Point, angle:Float, large:Bool, sweep:Bool, p:Point, relative:Bool);
	CClose;
}
