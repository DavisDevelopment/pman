package foundation;

import tannus.html.Element;

using StringTools;

class Label extends Widget {
	/* Constructor Function */
	public function new():Void {
		super();

		el = '<label></label>';

		position = After;
	}

/* === Instance Methods === */

	/**
	  * Apply the given options
	  */
	public function applyOptions(?o : LabelOptions):Void {
		if (o != null) {
			if (o.position != null)
				position = o.position;
		}
	}

	/**
	  * Attach [this] to the given Widget
	  */
	public function link(w : Widget):Void {
		owner = w;
		switch ( position ) {
			case Before:
				w.before( this );

			case After:
				w.after( this );
		}
	}

/* === Computed Instance Fields === */

	public var ownerId(get, set):Null<String>;
	private inline function get_ownerId():Null<String> return el['for'];
	private inline function set_ownerId(v : Null<String>):Null<String> return (el['for'] = v);

	public var owner(get, set):Null<Widget>;
	private function get_owner():Null<Widget> {
		if (ownerId != null) {
			var oe:Element = '#$uid';
			return oe.data( Widget.DATAKEY );
		}
		else return null;
	}
	private function set_owner(v : Null<Widget>):Null<Widget> {
		if (v != null) {
			ownerId = v.uid;
		}
		else {
			ownerId = null;
		}
		return owner;
	}

/* === Instance Fields === */

	public var position : LabelPos;
}

typedef LabelOptions = {
	?position : LabelPos
};

@:enum
abstract LabelPos (String) to String {
/* == Constructs == */
	var Before = 'before';
	var After = 'after';

/* == Methods == */

	/**
	  * Create a LabelPos from a String
	  */
	@:from
	public static function fromString(s : String):LabelPos {
		switch (s.trim().toLowerCase()) {
			case 'before':
				return Before;

			case 'after':
				return After;

			default:
				throw 'Error: "$s" is not a valid LabelPos';
				return After;
		}
	}
}
