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
class FloatInput extends DOMInput<Float> {
	/* Constructor Function */
	public function new():Void {
		super();

		ntype = 'number';
	}

/* === Instance Methods === */

	override public function getValue():Float return iel.valueAsNumber;
	override public function setValue(v : Float):Float return (iel.valueAsNumber = v);
}
