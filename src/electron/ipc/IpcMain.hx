package electron.ipc;

import electron.ext.WebContents;
import electron.ext.IpcMain.IpcMainEvent in Ime;
import electron.ext.IpcMain in S;

import haxe.extern.Rest;

//using Std;
//using Reflect;

class IpcMain {
	/**
	  * register an event handler
	  */
	public static inline function on(channel:String, handler:IpcMainEvent->Array<Dynamic>->Void):Void {
		S.on(channel, _toRest( handler ));
	}

	/**
	  * register an event handler
	  */
	public static inline function once(channel:String, handler:IpcMainEvent->Array<Dynamic>->Void):Void {
		S.once(channel, _toRest( handler ));
	}

/* === Static Utility Methods === */

	/**
	  * create a JavaScript-style handler from a Haxe-style one
	  */
	private static function _toRest(f : IpcMainEvent->Array<Dynamic>->Void):IpcMainEvent->Rest<Dynamic>->Void {
		var varArgFunc:Array<Dynamic>->Void = (function(varargs : Array<Dynamic>) {
			var raw_event:Ime = varargs[0];
			var args = varargs.slice( 1 );
			f(event, args);
		});
		return cast Reflect.makeVarArgs( varArgFunc );
	}
}

/*
class ImeSender {
	public function new(wc : WebContents):Void {
		webContents = wc;
	}


	public var webContents : WebContents;
	private var c(get, never):WebContents;
	private inline function get_c() return webContents;
}
*/
