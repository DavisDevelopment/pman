package electron.ext;

import haxe.Constraints.Function;

@:jsRequire('electron', 'ipcRenderer')
extern class IpcRenderer {
	public static function on(channel:String, callback:IpcRendererEvent->Array<Dynamic>->Void):Void;
	public static function once(channel:String, callback:IpcRendererEvent->Array<Dynamic>->Void):Void;

	public static function removeListener(channel:String, listener:Function):Void;
	public static function removeAllListeners(?channel : String):Void;

	public static function send(channel:String, data:Array<Dynamic>):Void;
	public static function sendToHost(channel:String, data:Array<Dynamic>):Void;
	public static function sendSync<T>(channel:String, data:Array<Dynamic>):T;
}

typedef IpcRendererEvent = {
	sender : IpcRendererMessageSender
};

extern class IpcRendererMessageSender {
	public function send(channel:String, data:Array<Dynamic>):Void;
	public function sendSync<T>(channel:String, data:Array<Dynamic>):T;
	public function sendTo(webContentsId:Int, channel:String, data:Array<Dynamic>):Void;
	public function sendToAll(webContentsId:Int, channel:String, data:Array<Dynamic>):Void;
}
