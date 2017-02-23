package foundation;

import tannus.ds.Delta;
import tannus.io.Signal;

import foundation.TextualWidget;
import foundation.IInput;

import js.html.InputElement;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;

class DOMInput<T> extends Input<T> {
	/* Constructor Function */
	public function new():Void {
		super();

		changed = new Signal();
		el = '<input></input>';

		__listen();
	}

/* === Instance Methods === */

	/* shift focus to [this] Input */
	public function focus():Void iel.focus();

	/* highlight all or part of [this]'s value */
	public function select(?start:Int, ?end:Int):Void {
		iel.select();
		if (start != null) {
			iel.selectionStart = start;
			iel.selectionEnd = (end == null ? iel.value.length : end);
		}
	}

	/**
	  * Listen for changes to [this] input
	  */
	private function __listen():Void {
		forwardEvent( 'change' );
		on('change', __change);
	}

	/**
	  * Handle a 'change' event
	  */
	private function __change(event : Dynamic):Void {
		var delta = new Delta(getValue(), lastValue);
		lastValue = getValue();
		changed.call( delta );
	}

	/**
	  * Add a Label to [this] Input
	  */
	public function label(txt : String):Void {
		onactivate(function() {
			if (_label == null) {
				_label = new Label();
				_label.owner = this;
				after( _label );
			}

			_label.text = txt;
		});
	}

	/**
	  * Get the value of [this] Input
	  */
	override public function getValue():Null<T> {
		return untyped iel.value;
	}

	/**
	  * Set the value of [this] Input
	  */
	override public function setValue(v : Null<T>):Void {
		iel.value = untyped v;
	}

/* === Instance Fields === */

	private var ntype(get, set):String;
	private inline function get_ntype():String return iel.type;
	private inline function set_ntype(v : String):String return (iel.type = v);

	/* reference to the underlying input */
	public var iel(get, never):InputElement;
	private function get_iel():InputElement return cast el.at( 0 );

	public var changed : Signal<Delta<T>>;
	private var lastValue : Null<T> = null;
	private var _label : Null<Label> = null;
}
