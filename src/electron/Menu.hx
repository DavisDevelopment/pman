package electron;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;

import electron.ext.Menu in M;
import electron.ext.MenuItem in Mi;
import electron.ext.MenuItem.MenuItemOptions;
import electron.ext.MenuItem.MenuItemRole;
import electron.ext.MenuItem.MenuItemType;
import electron.ext.NativeImage;
import electron.ext.BrowserWindow;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Menu {
	/* Constructor Function */
	public function new():Void {
		items = new Array();
	}

/* === Instance Methods === */

	public inline function append(item : MenuItem):Void {
		items.push( item );
	}
	public inline function insert(pos:Int, item:MenuItem):Void {
		items.insert(pos, item);
	}

	/**
	  * transpose [this] Object-model
	  */
	public function pack():M {
		var em:M = new M();
		for (item in items) {
			var emi:Mi = item.pack();
			em.append( emi );
		}
		return em;
	}

/* === Instance Fields === */

	public var items : Array<MenuItem>;

/* === Class Methods === */

	public static function buildFromTemplate(template : Array<MenuItemOptions>):Menu {
		var menu = new Menu();
		for (info in template) {
			menu.append(new MenuItem( info ));
		}
		return menu;
	}
	public static inline function setApplicationMenu(menu : Menu):Void {
		M.setApplicationMenu(menu.pack());
	}
}
