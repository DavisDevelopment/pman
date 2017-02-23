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
class TextInput extends DOMInput<String> {
	/* Constructor Function */
	public function new():Void {
		super();

		ntype = 'text';

		forwardEvents(['input', 'keypress', 'keydown', 'keyup'], el, tannus.events.KeyboardEvent.fromJqEvent);
	}

	public var placeholder(get, set):String;
	private inline function get_placeholder():String return (el['placeholder'].or(''));
	private inline function set_placeholder(v : String):String return (el['placeholder'] = v);
}
