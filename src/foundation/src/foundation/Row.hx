package foundation;

import foundation.Pane;

import tannus.ds.*;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

class Row extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'row' );
	}

/* === Instance Methods === */

	/* specify whether to 'collapse' [this] Row */
	public inline function collapse(doit:Bool=true, breakpoint:String=''):Void {
		(doit?addClass:removeClass)(breakpoint == null ? 'collapse' : '$breakpoint-collapse');
	}

	/* [breakpoint=null] remove the 'collapse' class (if present) */
	public function uncollapse(?breakpoint : String):Void {
		if (breakpoint == null) {
			removeClass( 'collapse' );
		}
		else {
			removeClass( '$breakpoint-collapse' );
			addClass( '$breakpoint-uncollapse' );
		}
	}

/* === Computed Instance Fields === */

	/* the list of alignments currently applied to [this] Row */
	public var alignments(get, set):Array<RowAlign>;
	private function get_alignments():Array<RowAlign> {
		return classes().macmapfilter(_.startsWith('align-'), _.after('align-'));
	}
	private function set_alignments(list : Array<RowAlign>):Array<RowAlign> {
		for (x in alignments)
			removeClass('align-' + x);
		for (x in list)
			addClass('align-' + x);
		return list;
	}
}

@:enum
abstract RowAlign (String) from String to String {
	var Right = 'right';
	var Center = 'center';
	var Justify = 'justify';
	var Spaced = 'spaced';
	var Top = 'top';
	var Middle = 'middle';
	var Bottom = 'bottom';
	var Stretch = 'stretch';
}
