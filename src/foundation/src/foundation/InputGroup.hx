package foundation;

import tannus.html.Element;
import tannus.events.*;

import foundation.TextualWidget;
import foundation.IInput;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;

class InputGroup<T> extends Pane {
	/* Constructor Function */
	public function new(f : Input<T>):Void {
		super();

		addClass( 'input-group' );

		groupLabel = new GroupLabel();
		groupLabel.css['display'] = 'none';
		append( groupLabel );
		groupField = f;
		append( groupField );
		groupButton = new GroupButton();
		append( groupButton );
	}

/* === Computed Instance Fields === */

	

/* === Instance Fields === */

	public var groupLabel : GroupLabel;
	public var groupField : Input<T>;
	public var groupButton : GroupButton;
}

class GroupLabel extends Span {
	public function new(){
		super();
		addClass('input-group-label');
	}
}

class GroupButton extends Button {
	public function new(){
		super(' ');

		el = '<input type="submit" class="button" />';

		forwardEvent('click', null, MouseEvent.fromJqEvent);
	}

	override private function get_text():String return el.attributes.get( 'value' );
	override private function set_text(v : String):String return el.attributes.set('value', v);
}
