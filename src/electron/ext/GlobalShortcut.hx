package electron.ext;

#if main_process
@:jsRequire('electron', 'globalShortcut')
#elseif renderer_process
@:jsRequire('electron', 'remote.globalShortcut')
#end
extern class GlobalShortcut {
	static function register(accelerator:String, callback:Void->Void):Void;
	static function isRegistered(accelerator : String):Bool;
	static function unregister(accelerator : String):Void;
	static function unregisterAll():Void;
}
