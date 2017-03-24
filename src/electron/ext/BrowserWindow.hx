package electron.ext;

import tannus.ds.Object;
import tannus.node.EventEmitter;

#if main_process
@:jsRequire('electron', 'BrowserWindow')
#elseif renderer_process
@:jsRequire('electron', 'remote.BrowserWindow')
#end
extern class BrowserWindow extends EventEmitter {
/* === Static Methods === */

	static function getAllWindows():Array<BrowserWindow>;
	static function getFocusedWindow():Null<BrowserWindow>;
	static function fromId(id : Int):Null<BrowserWindow>;

	static function addDevToolsExtension(path:String):Void;
	static function removeDevToolsExtension(name:String):Void;
	@:native('getDevToolsExtensions')
	static function getDevToolsExtensions_raw():Dynamic;
	inline static function getDevToolsExtensions():Object {
	    return new Object(getDevToolsExtensions_raw());
	};

/* === Instance Fields === */

	var webContents : WebContents;
	var id : Int;

/* === Instance Methods === */

	function new(?options : BrowserWindowOptions):Void;
	function loadURL(url:String):Void;
	function destroy():Void;
	function close():Void;
	function focus():Void;
	function blur():Void;
	function isFocused():Bool;
	function isDestroyed():Bool;
	function show():Void;
	function showInactive():Void;
	function hide():Void;
	function isVisible():Bool;
	function isModal():Bool;
	function maximize():Void;
	function unmaximize():Void;
	function isMaximized():Bool;
	function minimize():Void;
	function restore():Void;
	function isMinimized():Bool;
	function setFullScreen(v : Bool):Void;
	function isFullScreen():Bool;
	function setBounds(rect : Dynamic):Void;
	function getBounds():Dynamic;
	function setContentBounds(rect : Dynamic):Void;
	function getContentBounds():Dynamic;
	function setSize(w:Int, h:Int):Void;
	function getSize():Array<Int>;
	function setContentSize(w:Int, h:Int):Void;
	function getContentSize():Array<Int>;
	function setResizable(v : Bool):Void;
	function isResizable():Bool;
	function setMovable(v : Bool):Void;
	function isMovable():Bool;
}

typedef BrowserWindowOptions = {
	?width:Int,
	?height:Int,
	?x:Int,
	?y:Int,
	?useContentSize:Bool,
	?center:Bool,
	?minWidth:Int,
	?minHeight:Int,
	?maxWidth:Int,
	?maxHeight:Int,
	?resizable:Bool,
	?movable:Bool,
	?minimizable:Bool,
	?maximizable:Bool,
	?closable:Bool,
	?focusable:Bool,
	?alwaysOnTop:Bool,
	?fullscreen:Bool,
	?fullscreenable:Bool,
	?skipTaskbar:Bool,
	?kiosk:Bool,
	?title:String,
	?icon:String,
	?show:Bool,
	?frame:Bool,
	?parent:BrowserWindow,
	?modal:Bool,
	?acceptFirstMouse:Bool,
	?disableAutoHideCursor:Bool,
	?enableLargerThanScreen:Bool,
	?backgroundColor:String,
	?hasShadow:Bool,
	?darkTheme:Bool,
	?transparent:Bool,
	?type:BrowserWindowType,
	?titleBarStyle:TitleBarStyle,
	?thickFrame:Bool,
	?webPreferences:WebPreferences
};

typedef WebPreferences = {
	?devTools:Bool,
	?nodeIntegration:Bool,
	?preload:String,
	?session:Session,
	?partition:String,
	?zoomFactor:Float,
	?javascript:Bool,
	?webSecurity:Bool,
	?allowDisplayingInsecureContent:Bool,
	?allowRunningInsecureContent:Bool,
	?images:Bool,
	?textAreasResizable:Bool,
	?webgl:Bool,
	?webaudio:Bool,
	?plugins:Bool,
	?experimentalFeatures:Bool,
	?experimentalCanvasFeatures:Bool
};

@:enum
abstract TitleBarStyle (String) from String {
	var Default = 'default';
	var Hidden = 'hidden';
	var HiddenInset = 'hidden-inset';
}

@:enum
abstract BrowserWindowType (String) from String to String {
	var Desktop = 'desktop';
	var Dock = 'dock';
	var Toolbar = 'toolbar';
	var Splash = 'splash';
	var Notification = 'notification';
}
