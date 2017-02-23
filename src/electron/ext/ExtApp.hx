package electron.ext;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

#if main_process
@:jsRequire('electron', 'app')
#elseif renderer_process
@:jsRequire('electron', 'remote.app')
#end
extern class ExtApp {
	public static function on(event:String, f:Function):Void;
	public static function quit():Void;
	public static function exit(?code : Int):Void;
	public static function relaunch(?options : ExtAppRelaunchOptions):Void;
	public static function isReady():Bool;
	public static function focus():Void;
	public static function getAppPath():String;
	public static function getPath(name : ExtAppNamedPath):String;
	public static function getVersion():String;
	public static function getName():String;
}

typedef ExtAppRelaunchOptions = {
	?args:Array<String>,
	?execPath:String
};

@:enum
abstract ExtAppNamedPath (String) from String to String {
	var Home = 'home';
	var AppData = 'appData';
	var UserData = 'userData';
	var Temp = 'temp';
	var Exe = 'exe';
	var Module = 'module';
	var Desktop = 'desktop';
	var Documents = 'documents';
	var Downloads = 'downloads';
	var Pictures = 'pictures';
	var Videos = 'videos';
}
