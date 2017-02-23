package foundation;

import foundation.Widget;
import tannus.graphics.Color;

import foundation.styles.TextAlign;

class TextualWidget extends Widget {
	/* Constructor Function */
	public function new():Void {
		super();
	}

/* === Computed Instance Fields === */

	/**
	  * The Color of the text
	  */
	public var textColor(get, set):Color;
	private function get_textColor():Color {
		var tc:String = el.css('color');
		return Color.fromString( tc );
	}
	private function set_textColor(tc : Color):Color {
		el.css('color', tc.toString());
		return textColor;
	}

	/**
	  * The 'text-align' property of [this] Element
	  */
	public var textAlign(get, set):TextAlign;
	private inline function get_textAlign():TextAlign {
		return el.css('text-align');
	}
	private inline function set_textAlign(v : TextAlign):TextAlign {
		el.css('text-align', untyped v);
		return v;
	}

	/**
	  * The Font-Family of the text
	  */
	public var fontFamily(get, set):String;
	private function get_fontFamily():String {
		return el.css('font-family');
	}
	private function set_fontFamily(nf : String):String {
		el.css('font-family', nf);
		return fontFamily;
	}

	public var fontSize(get, set):String;
	private function get_fontSize():String {
		return el.css('font-size');
	}
	private function set_fontSize(nf : String):String {
		el.css('font-size', nf);
		return fontSize;
	}

	public var lineHeight(get, set):String;
	private function get_lineHeight():String {
		return el.css('line-height');
	}
	private function set_lineHeight(nf : String):String {
		el.css('line-height', nf);
		return lineHeight;
	}
}
