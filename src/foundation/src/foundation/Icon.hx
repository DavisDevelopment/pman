package foundation;

import foundation.IconType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;

class Icon extends TextualWidget {
	/* Constructor Function */
	public function new(?type : IconType):Void {
		super();

		el = '<i></i>';

		if (type != null) {
			this.type = type;
		}
	}

/* === Computed Instance Fields === */

	public var type(get, set):Null<IconType>;
	private function get_type():Null<IconType> {
		return classes().macfirstMatch(_.startsWith('fi-'));
	}
	private function set_type(v : Null<IconType>):Null<IconType> {
		var t = type;
		if (t != null) {
			removeClass( t );
		}
		if (v != null) {
			addClass( v );
		}
		return type;
	}
}
