package foundation;

import foundation.TextualWidget;
import foundation.IInput;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;

/**
  * class TextInput wraps js.html.InputElement[type=text]
  */
class BoolInput extends DOMInput<Bool> {
	/* Constructor Function */
	public function new():Void {
		super();

		ntype = 'checkbox';
	}

/* === Instance Methods === */

	override public function getValue():Null<Bool> return iel.checked;
	override public function setValue(v : Null<Bool>):Void (iel.checked = v);

/* === Computed Instance Fields === */

}
