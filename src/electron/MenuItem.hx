package electron;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;

import electron.ext.MenuItem in Mi;
import electron.ext.MenuItem.MenuItemOptions;
import electron.ext.MenuItem.MenuItemRole;
import electron.ext.MenuItem.MenuItemType;
import electron.ext.NativeImage;
import electron.ext.BrowserWindow;

import electron.Tools.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MenuItem {
	/* Constructor Function */
	public function new(?info : MenuItemOptions):Void {
		type = Normal;
		label = 'Item';
		sublabel = null;
		accelerator = null;
		icon = null;
		enabled = true;
		visible = true;
		checked = false;
		id = null;
		position = null;
		click = null;
		submenu = new Array();

		if (info != null) {
			pullOptions( info );
		}
	}

/* === Instance Methods === */

	/**
	  * 'pack' [this] into a native electron MenuItem
	  */
	public function pack():Mi {
		var item = new Mi({
			type: type,
			label: label,
			sublabel: sublabel,
			accelerator: accelerator,
			icon: icon,
			enabled: enabled,
			visible: visible,
			checked: checked,
			id: id,
			position: position,
			click: _onClick,
			submenu: (submenu.empty()?null:submenu.map.fn(_.pack()))
		});
		return item;
	}

	/**
	  * pull data from MenuItemOptions
	  */
	private function pullOptions(o : MenuItemOptions):Void {
		if (o.type != null) type = o.type;
		if (o.label != null) label = o.label;
		if (o.sublabel != null) sublabel = o.sublabel;
		if (o.accelerator != null) accelerator = o.accelerator;
		if (o.icon != null) {
			if (Std.is(o.icon, electron.ext.ExtNativeImage)) {
				icon = cast o.icon;
			}
			else if (Std.is(o.icon, String)) {
				icon = NativeImage.createFromPath( o.icon );
			}
		}
		if (o.enabled != null) enabled = o.enabled;
		if (o.visible != null) visible = o.visible;
		if (o.checked != null) checked = o.checked;
		if (o.id != null) id = o.id;
		if (o.position != null) position = o.position;
		if (o.click != null) {
			click = o.click;
		}
		if (o.submenu != null) {
			for (x in o.submenu) {
				submenu.push(new MenuItem( x ));
			}
		}
	}

	/**
	  * underlying 'click' handler
	  */
	private function _onClick(item:Mi, window:BrowserWindow, event:Dynamic):Void {
		onClick(item, window, event);
	}

	/**
	  * primary click handler
	  */
	public function onClick(item:Mi, window:BrowserWindow, event:Dynamic):Void {
		if (click != null) {
			click(item, window, event);
		}
	}

/* === Instance Fields === */

	public var type : MenuItemType;
	public var label : String;
	public var sublabel : Null<String>;
	public var accelerator : Null<String>;
	public var icon : Null<NativeImage>;
	public var enabled : Bool;
	public var visible : Bool;
	public var checked : Null<Bool>;
	public var id : Null<String>;
	public var position : Null<String>;
	public var click : Null<MenuItem -> BrowserWindow -> Dynamic -> Void>;
	public var submenu : Array<MenuItem>;
}
