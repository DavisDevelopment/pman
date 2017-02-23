package foundation;

import tannus.ds.Delta;
import tannus.io.Signal;

import tannus.html.Element;
import js.html.SelectElement;
import js.html.OptionElement;

import haxe.Constraints.FlatEnum;

using Lambda;
using tannus.ds.ArrayTools;

class Select<T> extends Input<T> {
	/* Constructor Function */
	public function new():Void {
		super();

		el = '<select></select>';
		options = new Array();
		onchange = new Signal();
		
		__listen();
	}

/* === Instance Methods === */

	/* attach the given Option to [this] */
	public function addOption(o : Option<T>):Option<T> {
		append( o );
		options.push( o );
		return o;
	}

	/* add an Option to [this] */
	public inline function option(text:String, value:T):Option<T> {
		return addOption(new Option(this, text, value));
	}

	/* get all Options attached to [this] */
	public inline function getOptions():Array<Option<T>> {
		return options.copy();
	}

	/* get the current value of [this] */
	override public function getValue():Null<T> {
		return selectedOption.value;
	}

	/* set the current value of [this] */
	override public function setValue(v : T):Void {
		for (o in options) {
			if (o.value == v) {
				selectedOption = o;
			}
		}
	}

	/* listen for incoming events */
	private function __listen():Void {
		var prev:Null<T> = null;
		
		el.on('change', function(event : Dynamic):Void {
			var curr = getValue();
			var change:Delta<T> = new Delta(curr, prev);
			prev = curr;
			dispatch('change', change);
		});

		on('change', onchange.call.bind(_));
	}

	/* apply and modify label */
	public function label(txt:String, ?options:Label.LabelOptions):Void {
		if (_label == null) {
			_label = new Label();
			_label.applyOptions( options );
			_label.link( this );
		}
		_label.text = txt;
	}

/* === Computed Instance Fields === */

	/* the Option which is currently selected */
	public var selectedOption(get, set):Option<T>;
	private inline function get_selectedOption():Option<T> return options[s.selectedIndex];
	private function set_selectedOption(v : Option<T>):Option<T> {
		s.selectedIndex = options.indexOf( v );
		return selectedOption;
	}

	/* [s] as it's underlying type */
	public var s(get, never):SelectElement;
	private inline function get_s():SelectElement return cast el.at( 0 );

/* === Instance Fields === */

	/* the Options attached to [this] */
	private var options : Array<Option<T>>;

	/* the Signal fired when the value of [this] changes */
	public var onchange : Signal<Delta<T>>;

	private var _label : Null<Label> = null;

/* === Static Methods === */

	/**
	  * Create a Select from two arrays of values
	  */
	public static function fromArray<T>(values:Array<T>, ?nameof:T->String):Select<T> {
		if (nameof == null) nameof = Std.string;
		var sel:Select<T> = new Select();
		for (v in values) {
			sel.option(nameof( v ), v);
		}
		return sel;
	}

	/**
	  * Create a Select from a Map
	  */
	public static function fromMap<T>(map : Map<String, T>):Select<T> {
		var sel:Select<T> = new Select();
		for (name in map.keys()) {
			sel.option(name, map.get( name ));
		}
		return sel;
	}
}

class Option<T> extends Widget {
	/* Constructor Function */
	public function new(s:Select<T>, t:String, v:T):Void {
		super();

		el = '<option></option>';
		el.data('hxModel:Option', this);
		text = t;
		value = v;
	}

/* === Computed Instance Fields === */

	public var o(get, never):OptionElement;
	private inline function get_o():OptionElement return cast el.at( 0 );

	public var value(get, set):T;
	private inline function get_value():T return untyped el.data( '__v' );
	private inline function set_value(v : T):T {
		el.data('__v', v);
		return value;
	}
}
