package foundation;

import tannus.io.Ptr;
import tannus.ds.EitherType;
import tannus.ds.Maybe;
import tannus.ds.Obj;
import tannus.html.Element;
import tannus.html.ElStyles;

import tannus.graphics.Color;

import foundation.styles.EFloat;
import foundation.styles.*;

import Std.*;

class Styles {
	/* Constructor Function */
	public function new(ref : Ptr<Element>):Void {
		_el = ref;
	}

/* === Instance Methods === */

	/**
	  * Get a reference to the 'styles' field of the element in question
	  */
	private function css():ElStyles {
		var e = el;
		if (e == null) {
			throw 'WidgetError: Cannot modify an Element which does not exist!';
		} 
		else {
			return e.style;
		}
	}

	/**
	  * get/set the margin of [this] Element
	  */
	public function margin(?nm : Dynamic):Array<Float> {
		if (nm != null) {
			if (is(nm, Array)) {
				var na:Array<Float> = cast nm;
				marginTop = na.shift();
				marginRight = na.shift();
				marginBottom = na.shift();
				marginLeft = na.shift();
			}
			else if (is(nm, Float)) {
				marginTop = cast nm;
				marginBottom = cast nm;
				marginLeft = cast nm;
				marginRight = cast nm;
			}
		}
		return [marginTop, marginRight, marginBottom, marginLeft];
	}

	/**
	  * get/set the padding of [this] Element
	  */
	public function padding(?top:Maybe<Float>, ?right:Maybe<Float>, ?bottom:Maybe<Float>, ?left:Maybe<Float>) {
		var c = css();
		if (top.exists && right.exists && bottom.exists && left.exists) {
			c['padding-top'] = (top.value + 'px');
			c['padding-right'] = (right.value + 'px');
			c['padding-left'] = (left.value + 'px');
			c['padding-bottom'] = (bottom.value + 'px');
		}
		else if (top.exists) {
			c['padding'] = (top.value + 'px');
		}

		return {
			'top': parseFloat(c['padding-top']),
			'bottom': parseFloat(c['padding-bottom']),
			'left': parseFloat(c['padding-left']),
			'right': parseFloat(c['padding-right'])
		};
	}

	/**
	  * get/set the border of [this] Element
	  */
	public function border(?type:Maybe<String>, ?color:Maybe<Color>, ?size:Maybe<Float>) {
		var c = css();
		/* if a value was provided, assign it */
		if (type.exists && color.exists && size.exists) {
			c['border-style'] = type.value;
			c['border-color'] = color.value.toString();
			c['border-width'] = string(size.value);
		}

		/* Return data about the border */
		return {
			'style' : c['border-style'],
			'color' : Color.fromString(c['border-color']),
			'size' : parseFloat(c['border-width'])
		};
	}

	/**
	  * get/set the background-color
	  */
	public function backgroundColor(?color : Color):Color {
		var c = css();
		if (color != null) {
			c['background-color'] = string( color );
		}
		return Color.fromString(c['background-color']);
	}

	/**
	  * get/set the float
	  */
	public function float(?dir : EFloat):EFloat {
		var c = css();
		if (dir == null) {
			return c['float'];
		}
		else {
			return (c['float'] = dir);
		}
	}

	/**
	  * get/set position
	  */
	public function position(?pos : Pos):Pos {
		var c = css();
		if (pos == null) {
			var tpos:Obj = Obj.fromDynamic(c.gets(['top', 'left', 'bottom', 'right']));
			trace(tpos.toDyn());
			tpos.set('type', c['position']);
			return new Pos(cast tpos.toDyn());
		}
		else {
			c.set('position', pos.type);
			if (pos.top != null) c.set('top', (pos.top + 'px'));
			if (pos.left != null) c.set('left', (pos.left + 'px'));
			if (pos.bottom != null) c.set('bottom', (pos.bottom + 'px'));
			if (pos.right != null) c.set('right', (pos.right + 'px'));
			return position();
		}
	}

	/**
	  * set the display
	  */
	public function display(d : Display):Void {
		css().set('display', d);
	}

/* === Computed Instance Fields === */

	/**
	  * The Element in question
	  */
	private var el(get, never):Null<Element>;
	private inline function get_el() return _el._;

	/**
	  * The left-margin of [this] Element
	  */
	public var marginLeft(get, set):Float;
	private function get_marginLeft() return parseFloat(css()['margin-left']);
	private function set_marginLeft(ml : Float):Float {
		var c = css();
		c['margin-left'] = (ml + 'px');
		return ml;
	}

	/**
	  * The right-margin of [this] Element
	  */
	public var marginRight(get, set):Float;
	private function get_marginRight() return parseFloat(css()['margin-right']);
	private function set_marginRight(mr : Float):Float {
		var c = css();
		c['margin-right'] = (mr + 'px');
		return mr;
	}

	/**
	  * The top-margin of [this] Element
	  */
	public var marginTop(get, set):Float;
	private function get_marginTop() return parseFloat(css()['margin-top']);
	private function set_marginTop(mr : Float):Float {
		var c = css();
		c['margin-top'] = (mr + 'px');
		return mr;
	}

	/**
	  * The top-margin of [this] Element
	  */
	public var marginBottom(get, set):Float;
	private function get_marginBottom() return parseFloat(css()['margin-bottom']);
	private function set_marginBottom(mr : Float):Float {
		var c = css();
		c['margin-bottom'] = (mr + 'px');
		return mr;
	}



/* === Instance Fields === */

	/* A pointer to the Element in question */
	private var _el : Ptr<Element>;
}
