package electron.ext;

import haxe.extern.*;

import tannus.node.EventEmitter;

import electron.ext.WebContentsInterface;

extern class WebContents extends EventEmitter implements WebContentsInterface {
/* === Instance Methods === */

	function loadURL(url:String, ?options:LoadUrlOptions):Void;
	function downloadURL(url : String):Void;
	function getURL():String;
	function getTitle():String;
	function isDestroyed():Bool;
	function isFocused():Bool;
	function isLoading():Bool;
	function isLoadingMainFrame():Bool;
	function isWaitingForResponse():Bool;
	function stop():Void;
	function reload():Void;
	function reloadIgnoringCache():Void;
	function canGoBack():Bool;
	function canGoForward():Bool;
	function canGoToOffset(offset : Int):Bool;
	function clearHistory():Void;
	function goBack():Void;
	function goForward():Void;
	function goToIndex(i : Int):Void;
	function goToOffset(offset : Int):Void;
	function isCrashed():Bool;
	function getUserAgent():String;
	function setUserAgent(agent : String):Void;
	function insertCSS(css : String):Void;
	function executeJavaScript(code:String, ?userGesture:Bool, ?callback:Dynamic->Void):Void;
	function isAudioMuted():Bool;
	function setAudioMuted(v : Bool):Void;
	function setZoomFactor(factor : Float):Void;
	function getZoomFactor(f : Float->Void):Void;
	function setZoomLevel(level : Float):Void;
	function getZoomLevel(f : Float->Void):Void;
	function undo():Void;
	function redo():Void;
	function cut():Void;
	function copy():Void;
	function copyImageAt(x:Int, y:Int):Void;
	function paste():Void;
	function pasteAndMatchStyle():Void;
	function delete():Void;
	function selectAll():Void;
	function unselect():Void;
	function replace(text : String):Void;
	function insertText(text : String):Void;
	function addWorkSpace(path : String):Void;
	function removeWorkSpace(path : String):Void;
	function openDevTools(?options : OpenDevToolsOptions):Void;
	function closeDevTools():Void;
	function isDevToolsOpened():Bool;
	function isDevToolsFocused():Bool;
	function toggleDevTools():Void;
	function inspectElement(x:Int, y:Int):Void;
	function send(channel:String, data:Array<Dynamic>):Void;

	var id : Int;
	var session : Session;
	var hostWebContents : WebContents;
	var devToolsWebContents : WebContents;
}
