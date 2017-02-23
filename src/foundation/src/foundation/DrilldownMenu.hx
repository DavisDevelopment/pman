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

class DrilldownMenu extends List {
	/* Constructor Function */
	public function new():Void {
		super( false );

		el['data-drilldown'] = 'yes';
		addClass( 'vertical' );
		addClass( 'menu' );
	}

/* === Instance Methods === */


}
