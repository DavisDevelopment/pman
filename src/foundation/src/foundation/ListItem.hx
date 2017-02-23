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

class ListItem extends Widget {
	/* Constructor Function */
	public function new(l:List, ?c:Dynamic):Void {
		super();

		el = '<li></li>';
		if (c != null) append( c );
	}
}
