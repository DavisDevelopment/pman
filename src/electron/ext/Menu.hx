package electron.ext;

import js.html.Window;

import electron.ext.MenuItem;

#if main_process
@:jsRequire('electron', 'Menu')
#elseif renderer_process
@:jsRequire('electron', 'remote.Menu')
#end
extern class Menu {
/* === Instance Fields === */

	public var items : Array<MenuItem>;

/* === Instance Methods === */

	public function new():Void;

	//@:overload(function(x:Float, y:Float):Void {})
	public function popup(options: {?x:Float,?y:Float,?window:BrowserWindow}):Void;
	public function append(item : MenuItem):Void;
	public function insert(pos:Int, item:MenuItem):Void;

/* === Static Methods === */

	public static function setApplicationMenu(menu : Menu):Void;
	public static function getApplicationMenu():Menu;
	public static function buildFromTemplate(template : Array<MenuItemOptions>):Menu;
}
