package foundation;

import foundation.Button;
import foundation.Link;
import foundation.List;

import tannus.html.Element;
import tannus.ds.Memory;

@:access(foundation.List)
class DropdownButton extends Button {
	/* Constructor Function */
	public function new(txt : String):Void {
		super( txt );
		list = new List();
		attach( list );

		__init_dropdown();
	}

/* === Instance Methods === */

	/**
	  * Initialize [this] Dropdown
	  */
	private function __init_dropdown():Void {
		var id:String = Memory.uniqueIdString('dropdown-');
		el.addClass('dropdown');
		var ela = el.attributes;
		ela += {
			'data-dropdown': id,
			'aria-controls': id,
			'aria-expanded': false
		};
		var la = list.el.attributes;
		la += {
			'id' : id,
			'data-dropdown-content': 'yes',
			'aria-hidden': true
		};
		list.el.addClass('f-dropdown');
		size = [Small];
		on('activate', function(x) {
			engage();
		});
	}

	/**
	  * Cast [this] to an Element
	  */
	override public function toElement():Element {
		return (el + list);
	}

	/**
	  * Add a Link to [this] Dropdown
	  */
	public function addButton(txt:String, ?url:String):Link {
		var link = new Link(txt, url);
		list.addItem( link );
		return link;
	}

	/**
	  * Get a Button from [this] Dropdown
	  */
	public function button(i : Int):Null<Link> {
		return untyped list.item( i );
	}

	/**
	  * Remove a Button from [this] Dropdown
	  */
	public function removeButton(btn : Link):Bool {
		var has = Lambda.has(list.items, btn);
		list.items.remove( btn );
		return has;
	}

/* === Instance Fields === */

	/* List of Links associated with [this] Dropdown */
	private var list : List;
}
