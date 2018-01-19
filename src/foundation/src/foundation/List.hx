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
      * attach an arbitrary item to [this] List
      */
    private function attachItem(thing:Dynamic, f:ListItem->Void):ListItem {
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
		return item;
    }

	/**
	  * Add a new List-Item to [this] List
	  */
	public function addItem(thing : Dynamic):ListItem {
	    return attachItem(thing, function(item) {
	        append( item );
	    });
	}

	public function prependItem(thing: Dynamic):ListItem {
	    return attachItem(thing, function(item) {
	        prepend( item );
	    });
	}

    /**
      * insert an item after another item
      */
	public function insertItemAfter(thing:Dynamic, child:Dynamic, ?test:Dynamic->Dynamic->Bool):ListItem {
	    return attachItem(thing, function(item : ListItem) {
	        var ci:Null<ListItem> = getItemFor( child );
	        if (ci == null) {
	            listItems.remove( item );
	        }
            else {
                item.after( ci );
            }
	    });
	}

    /**
      * insert an item before another item
      */
	public function insertItemBefore(thing:Dynamic, child:Dynamic, ?test:Dynamic->Dynamic->Bool):ListItem {
	    return attachItem(thing, function(item : ListItem) {
	        var ci:Null<ListItem> = getItemFor( child );
	        if (ci == null) {
	            listItems.remove( item );
	        }
            else {
                item.before( ci );
            }
	    });
	}

    /**
      * create an item for [thing]
      */
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
	  * get a listitem by index
	  */
	public inline function item(index : Int):Null<ListItem> {
		return listItems[ index ];
	}

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
            else if (item == thing) {
                return item;
            }
	    }
	    return null;
	}

	/**
	  * remove the given item
	  */
	public function removeItem(item:ListItem, detach:Bool=false):Void {
	    // remove [item] from [this] list
	    listItems.remove( item );
	    
	    // detach [item]'s content from it in the DOM
	    if ( detach ) {
	        if (Std.is(item.content, Widget)) {
	            cast(item.content, Widget).detach();
	        }
            else {
                (new Element( item.content )).detach();
            }
	    }

	    // detach [item]'s content from it on the object model
	    item.content = null;

	    // delete [item]
	    item.destroy();
	}

	/**
	  * remove the item for the given thing
	  */
	public function removeItemFor(thing:Dynamic, ?detach:Bool, ?test:Dynamic->Dynamic->Bool):Void {
	    var item = getItemFor(thing, test);
	    if (item != null) {
	        removeItem(item, detach);
	    }
        else {
            throw new tannus.utils.Error('Cannot remove non-existant item');
        }
	}

	/**
	  * empty [this] List out
	  */
	public function empty():Void {
	    var chel = new Element(el.children()).toArray();
	    for (child in chel) {
	        child.detach();
	    }
	    listItems = new Array();
	}

/* === Instance Fields === */

	/* The items of [this] list */
	private var listItems:Array<ListItem>;
}
