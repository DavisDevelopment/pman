package foundation;

import foundation.Pane;
import foundation.List;
import foundation.Link;
import foundation.Tab;

import tannus.html.Element;
import tannus.ds.Memory;

class TabbedPane extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();
		
		list = new List();
		append( list );

		content = new Pane();
		append( content );

		__init_tabs();
	}

/* === Instance Methods === */

	/**
	  * Initialize [this] TabbedPane
	  */
	private function __init_tabs():Void {
		list.el.addClass('tabs');
		list.el['data-tab'] = 'yes';
		content.el.addClass('tabs-content');
		
		on('activate', function(me) {
			engage();
		});

		addSignals(['toggled', 'opened', 'closed']);
		list.el.on('toggled', untyped function(event, tabel:Element) {
			var tab:Tab = cast tabel.find('a:first').data('tab');
			tab.dispatch('toggled', null);
			
			dispatch('toggled', tab);
			dispatch((tab.opened?'opened':'closed'), tab);
		});
	}

	/**
	  * Add a new Tab to [this] Pane
	  */
	public function addTab(title : String) {
		var tid:String = Memory.uniqueIdString('tab-');
		var t:Link = new Link(title, '#');
		list.addItem( t );
		var li:Element = t.el.parent();
		li.addClass('tab-title');
		t.href += tid;

		var c:Pane = new Pane();
		c.el.addClass('content');
		c.el['id'] = tid;
		content.append( c );
		if (_active)
			engage();
		return new Tab(t, c);
	}

/* === Computed Instance Fields === */

	/**
	  * Whether to display [this] TabbedPane vertically
	  */
	public var vertical(get, set):Bool;
	private function get_vertical() return list.el.is('.vertical');
	private function set_vertical(v : Bool):Bool {
		(v?list.el.addClass:list.el.removeClass)('vertical');
		return v;
	}

/* === Instance Fields === */

	/* The List of Tabs attached to [this] Pane */
	private var list : List;
	
	/* The list of Panes attached to [this] Pane */
	private var content : Pane;
}
