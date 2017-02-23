package electron.ext;

import haxe.extern.*;

import tannus.node.EventEmitter;
import tannus.node.Buffer;

import js.html.Element;

import electron.ext.WebContentsInterface;

extern class WebViewElement extends Element implements WebContentsInterface {
/* === <webview> attributes === */
	
	public var src : String;
	public var autosize : Bool;
	public var nodeintegration : Bool;
	public var plugins : Bool;
	public var preload : Null<String>;
	public var httpreferer : Null<String>;
	public var useragent : Null<String>;
	public var disablewebsecurity : Bool;
	public var partition : String;
	public var allowpopups : Bool;
	public var webpreferences : Null<String>;
	public var guestinstance : Null<String>;
	public var disableguestresize : Bool;

/* === WebContents inheritance === */

	public function loadURL(url:String, ?options:LoadUrlOptions):Void;
	public function downloadURL(url : String):Void;
	public function getURL():String;
	public function getTitle():String;
	public function isDestroyed():Bool;
	public function isFocused():Bool;
	public function isLoading():Bool;
	public function isLoadingMainFrame():Bool;
	public function isWaitingForResponse():Bool;
	public function stop():Void;
	public function reload():Void;
	public function reloadIgnoringCache():Void;
	public function canGoBack():Bool;
	public function canGoForward():Bool;
	public function canGoToOffset(offset : Int):Bool;
	public function clearHistory():Void;
	public function goBack():Void;
	public function goForward():Void;
	public function goToIndex(i : Int):Void;
	public function goToOffset(offset : Int):Void;
	public function isCrashed():Bool;
	public function getUserAgent():String;
	public function setUserAgent(agent : String):Void;
	public function insertCSS(css : String):Void;
	public function executeJavaScript(code:String, ?userGesture:Bool, ?callback:Dynamic->Void):Void;
	public function isAudioMuted():Bool;
	public function setAudioMuted(v : Bool):Void;
	public function setZoomFactor(factor : Float):Void;
	public function getZoomFactor(f : Float->Void):Void;
	public function setZoomLevel(level : Float):Void;
	public function getZoomLevel(f : Float->Void):Void;
	public function undo():Void;
	public function redo():Void;
	public function cut():Void;
	public function copy():Void;
	public function copyImageAt(x:Int, y:Int):Void;
	public function paste():Void;
	public function pasteAndMatchStyle():Void;
	public function delete():Void;
	public function selectAll():Void;
	public function unselect():Void;
	public function replace(text : String):Void;
	public function insertText(text : String):Void;
	public function addWorkSpace(path : String):Void;
	public function removeWorkSpace(path : String):Void;
	public function openDevTools(?options : OpenDevToolsOptions):Void;
	public function closeDevTools():Void;
	public function isDevToolsOpened():Bool;
	public function isDevToolsFocused():Bool;
	public function toggleDevTools():Void;
	public function inspectElement(x:Int, y:Int):Void;
	public function send(channel:String, data:Dynamic):Void;

	//public var id : Int;
	public var session : Session;
	public var hostWebContents : WebContents;
	public var devToolsWebContents : WebContents;
}
