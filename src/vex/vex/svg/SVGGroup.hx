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

@:expose( 'Group' )
class SVGGroup extends SVGElement {
	/* Constructor Function */
	public function new():Void {
		super();

		e = createElement( 'g' );
	}
}
