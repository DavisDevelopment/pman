package electron.ext;

import haxe.extern.EitherType;

import js.html.Event;
import js.html.Window;

#if renderer_process
@:jsRequire('electron', 'remote.MenuItem')
#elseif main_process
@:jsRequire('electron', 'MenuItem')
#end
extern class MenuItem {
	public function new(options : MenuItemOptions):Void;

	public dynamic function click(item:MenuItem, window:Window, event:Event):Void;

	public var enabled : Bool;
	public var visible : Bool;
	public var checked : Bool;
	public var label : String;
}

typedef MenuItemOptions = {
	?click : MenuItem -> Window -> Event -> Void,
	?role : MenuItemRole,
	?type : MenuItemType,
	?label : String,
	?sublabel : String,
	?accelerator : String,
	?icon : String,
	?enabled : Bool,
	?visible : Bool,
	?checked : Bool,
	?submenu : EitherType<Array<MenuItemOptions>, Menu>,
	?id : String,
	?position : String
};

@:enum
abstract MenuItemType (String) from String to String {
	var Normal = 'normal';
	var Separator = 'separator';
	var Submenu = 'submenu';
	var Checkbox = 'checkbox';
	var Radio = 'radio';
}

@:enum
abstract MenuItemRole (String) from String to String {}
