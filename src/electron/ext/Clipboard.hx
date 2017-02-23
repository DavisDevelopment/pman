package electron.ext;

@:jsRequire('electron', 'clipboard')
extern class Clipboard {
	static function readText(?type : String):String;
	static function writeText(text:String, ?type:String):Void;
	static function readImage(?type : String):Null<NativeImage>;
	static function writeImage(image:NativeImage, ?type:String):Void;
	static function availableFormats(?type : String):Array<String>;
	static function read(data:String, ?type:String):Null<String>;
	static function clear(?type : String):Void;
}
