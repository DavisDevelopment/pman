package electron.ext;

import haxe.extern.*;

import tannus.node.EventEmitter;
import tannus.node.Buffer;

extern class Session extends EventEmitter {
	function setDownloadPath(path : String):Void;
	function setUserAgent(userAgent : String):Void;
	function getUserAgent():String;
	function getBlobData(id:String, callback:Buffer->Void):Void;

	var cookies : Cookies;
}
