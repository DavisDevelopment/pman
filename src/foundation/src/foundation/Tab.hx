package foundation;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.io.EventDispatcher;

import foundation.Link;
import foundation.Pane;

class Tab extends Pane {
	/* Constructor Function */
	public function new(titl:Link, body:Pane):Void {
		super();
		title = titl;
		content = body;
		el = body.el;
		title.el.data('tab', this);

		addSignals(['toggled', 'opened', 'closed']);
		on('toggled', function(x) {
			dispatch((opened?'opened':'closed'), this);
		});
	}

/* === Instance Methods === */

	/**
	  * Open [this] Tab
	  */
	public function open():Void {
		title.click();
	}

	/**
	  * Close [this] Tab
	  */
	public function close():Void {
		title.el.removeClass('active');
		content.el.removeClass('active');
		dispatch('closed', this);
	}

/* === Computed Instance Fields === */

	/**
	  * Whether [this] Tab is currently open
	  */
	public var opened(get, never):Bool;
	private inline function get_opened():Bool {
		return (el.is('.active'));
	}

	/**
	  * The 'name' of [this] Tab
	  */
	public var name(get, set):String;
	private inline function get_name() return title.text;
	private inline function set_name(n : String) return (title.text = n);

/* === Instance Fields === */

	//- The Link which acts as the title for [this] Tab
	public var title : Link;

	//- The Pane which acts as the content for [this] Tab
	public var content : Pane;
}
