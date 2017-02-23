package electron.ext;

@:structInit
class FileFilter {
	/* Constructor Function */
	public function new(name:String, extensions:Array<String>):Void {
		this.name = name;
		this.extensions = extensions;
	}

/* === Instance Fields === */

	public var name : String;
	public var extensions : Array<String>;

/* === Static Fields === */

	public static var VIDEO : FileFilter;
	public static var AUDIO : FileFilter;

	public static function __init__():Void {
		VIDEO = new FileFilter('video', [
			'mp4', 'webm', 'ogg'
		]);
		AUDIO = new FileFilter('audio', [
			'mp3', 'ogg', 'wav'
		]);
	}
}
