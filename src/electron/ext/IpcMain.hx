package electron.ext;

import haxe.extern.Rest;
import haxe.Constraints.Function;

@:jsRequire('electron', 'ipcMain')
extern class IpcMain {
	public static function on(channel:String, callback:IpcMainEvent->Array<Dynamic>->Void):Void;
	public static function once(channel:String, callback:IpcMainEvent->Array<Dynamic>->Void):Void;
	//public static function send(channel:String, data:Rest<Dynamic>):Void;
	public static function removeListener(channel:String, listener:Function):Void;
	public static function removeAllListeners(?channel : String):Void;
}

typedef IpcMainEvent = {
	sender : WebContents,
	returnValue : Null<Dynamic>
};
