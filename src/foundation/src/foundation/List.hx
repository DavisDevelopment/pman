package foundation;

import tannus.html.Element;
import foundation.Widget;

import Std.*;

class List extends Widget {
	/* Constructor Function */
	public function new(ordered:Bool=true):Void {
		super();
		var tag:String = (ordered?'ul':'ol');
		el = '<$tag></$tag>';
		listItems = new Array();
	}

/* === Instance Methods === */

	/**
	  * Add a new List-Item to [this] List
	  */
	public function addItem(thing : Dynamic):Void {
		var item = new ListItem( this );
		if (Std.is(thing, Widget)) {
			var w:Widget = cast thing;
			item.append( w );
			listItems.push( item );
		}
		else {
			var w:Widget = new Widget();
			w.el = new Element( thing );
			item.append( w );
			listItems.push( item );
		}

		append( item );
		attach( item );
	}

	/**
	  * Remove an item from [this] List
	  */
	//public inline function item<T:Widget>(index : Int):Null<T> {
		//return untyped items[ index ];
	//}

/* === Instance Fields === */

	/* The items of [this] list */
	private var listItems:Array<Widget>;
}
