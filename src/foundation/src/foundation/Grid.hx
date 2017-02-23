package foundation;

import tannus.html.Element;
import tannus.html.ElAttributes;
import tannus.io.Ptr;
import tannus.io.Signal;

import foundation.List;

using Lambda;
using StringTools;

class Grid extends List {
	/* Constructor Function */
	public function new(?column_count:Int=3):Void {
		super();

		cols = column_count;
	}

/* === Computed Instance Fields === */

	/**
	  * The number of Blocks per row in [this] Grid
	  */
	public var cols(get, set):Int;
	private inline function get_cols() return _cols;
	private function set_cols(nc : Int) {
		var ls = el.classes.filter(function(s) return (s.indexOf('block-grid') == -1));
		ls.push('small-block-grid-$nc');
		el.classes = ls;
		_cols = nc;
		return _cols;
	}

/* === Instance Fields === */

	private var _cols:Int;
}
