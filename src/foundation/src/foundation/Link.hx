package foundation;

import foundation.TextualWidget;

class Link extends TextualWidget {
	/* Constructor Function */
	public function new(?txt:String, ?href:String):Void {
		super();
		el = '<a></a>';
		if (txt != null)
			text = txt;
		if (href != null)
			el['href'] = href;
		__init();
	}

/* === Instance Methods === */

	/**
	  * Initialize [this] Link
	  */
	private function __init():Void {
		addSignal('click');
		el.on('click', function(event) {
			dispatch('click', event);
		});
	}

	/**
	  * Emulate a 'click' event on [this] Link
	  */
	public function click():Void {
		el.click();
	}

/* === Computed Instance Methods === */

	/**
	  * The 'href' attribute of [this] Link
	  */
	public var href(get, set):String;
	private inline function get_href() return (el['href'].value);
	private function set_href(h : String):String {
		el['href'] = h;
		return h;
	}

	/**
	  * The 'target' attribute of [this] Link
	  */
	public var target(get, set):String;
	private inline function get_target() return el['target'].value;
	private function set_target(t : String):String {
		el['target'] = t;
		return t;
	}
}
