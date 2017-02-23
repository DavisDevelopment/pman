package foundation;

import Std.*;
import Std.is in istype;
import Math.*;
import tannus.math.TMath.*;
import tannus.internal.TypeTools;
import tannus.internal.CompileTime in Ct;
import foundation.Tools.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
//using foundation.Tools;

class Dropdown extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'dropdown-pane' );
		el['data-dropdown'] = '';

		ddi = Foundation.pluginInstance('Dropdown', [el]);

		build();
	}

/* === Instance Methods === */

	override public function activate():Void {
		super.activate();
	}

	override private function populate():Void {
		super.populate();
	}

	public function open():Void {
		ddi.open();
	}

	public function close():Void {
		ddi.close();
	}

	public function toggle():Void {
		ddi.toggle();
	}

/* === Instance Fields === */

	// Foundation.Dropdown instance itself
	private var ddi : Dynamic;
}
