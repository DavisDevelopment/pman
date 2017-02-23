package foundation;

import foundation.Button;
import foundation.Pane;
import foundation.List;
import foundation.Link;

import tannus.html.Element;
import tannus.ds.Memory;

class SplitButton extends Button {
	/* Constructor Function */
	public function new(txt : String):Void {
		super( txt );
		list = new List();
		attach( list );

		var id:String = Memory.uniqueIdString('dropdown-');
		el.append('<span data-dropdown="$id"></span>');
		el.append('</br>');
		el.addClass('split');
		var lst:Element = list.el;
		lst['id'] = id;
		lst['data-dropdown-content'] = 'yes';
		lst.addClass('f-dropdown');

		on('activate', function(me) engage());
	}

/* === Instance Methods === */

	/**
	  * Cast [this] to an Element
	  */
	override public function toElement():Element {
		return (el + list);
	}

	/**
	  * Add a sub-button to [this] Element
	  */
	public function addButton(txt:String, ?href:String):Link {
		var lnk:Link = new Link(txt, href);
		list.addItem( lnk );
		return lnk;
	}

	/**
	  * Get a Link from [this] SplitButton
	  */
	public function getButton(index : Int):Null<Link> {
		return untyped list.item(index);
	}

/* === Instance Fields === */

	/* The List of sub-buttons */
	private var list : List;
}
