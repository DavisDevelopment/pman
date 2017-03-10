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

    private function attachItem(thing:Dynamic, f:ListItem->Void):Void {
        var item : ListItem;
	    if (Std.is(thing, ListItem)) {
	        item = cast thing;
	    }
        else {
            item = createItemFor( thing );
        }
	    listItems.push( item );
		//append( item );
		f( item );
		//attach( item );
    }
	/**
	  * Add a new List-Item to [this] List
	  */
	public function addItem(thing : Dynamic):Void {
	    attachItem(thing, function(item) {
	        append( item );
	    });
	}

	public function insertItemAfter(thing:Dynamic, child:Dynamic, ?test:Dynamic->Dynamic->Bool):Void {
	    attachItem(thing, function(item : ListItem) {
	        var ci:Null<ListItem> = getItemFor( child );
	        if (ci == null) {
	            listItems.remove( item );
	        }
            else {
                item.after( ci );
            }
	    });
	}

	public function insertItemBefore(thing:Dynamic, child:Dynamic, ?test:Dynamic->Dynamic->Bool):Void {
	    attachItem(thing, function(item : ListItem) {
	        var ci:Null<ListItem> = getItemFor( child );
	        if (ci == null) {
	            listItems.remove( item );
	        }
            else {
                item.before( ci );
            }
	    });
	}

	public function createItemFor(thing : Dynamic):ListItem {
		var item = new ListItem( this );
		if (Std.is(thing, Widget)) {
			var w:Widget = cast thing;
			item.setContent( w );
		}
		else {
			var w:Widget = new Widget();
			w.el = new Element( thing );
			item.setContent( w );
		}
		return item;
	}

	/**
	  * Remove an item from [this] List
	  */
	//public inline function item<T:Widget>(index : Int):Null<T> {
		//return untyped items[ index ];
	//}

    /**
      * get the item for the given 'thing'
      */
	public function getItemFor(thing:Dynamic, ?test:Dynamic->Dynamic->Bool):Null<ListItem> {
	    for (item in listItems) {
	        if (test != null && test(item.content, thing)) {
	            return item;
	        }
            else if (item.content == thing) {
	            return item;
	        }
	    }
	    return null;
	}

	/**
	  * remove the given item
	  */
	public function removeItem(item : ListItem):Void {
	    item.detach();
	    listItems.remove( item );
	}

	/**
	  * remove the item for the given thing
	  */
	public function removeItemFor(thing:Dynamic, ?test:Dynamic->Dynamic->Bool):Void {
	    var item = getItemFor(thing, test);
	    if (item != null) {
	        removeItem( item );
	    }
	}

/* === Instance Fields === */

	/* The items of [this] list */
	private var listItems:Array<ListItem>;
}
