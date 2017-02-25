package electron.ext;

@:structInit
class FileFilter {
	/* Constructor Function */
	public function new(name:String, extensions:Array<String>):Void {
		this.name = name;
		this.extensions = extensions;
	}

/* === Instance Methods === */

    public function plus(other:FileFilter, ?sumname:String):FileFilter {
        if (sumname == null)
            sumname = (name + other.name);
        return new FileFilter(sumname, extensions.concat(other.extensions));
    }

/* === Instance Fields === */

	public var name : String;
	public var extensions : Array<String>;

/* === Static Fields === */

	public static var VIDEO : FileFilter;
	public static var AUDIO : FileFilter;
	public static var PLAYLIST : FileFilter;
	public static var ALL : FileFilter;

	public static function __init__():Void {
		VIDEO = new FileFilter('Video Files', [
			'mp4', 'webm', 'ogg'
		]);
		AUDIO = new FileFilter('Audio Files', [
			'mp3', 'ogg', 'wav'
		]);
		PLAYLIST = new FileFilter('Playlist Files', [
			'm3u', 'xspf', 'pls', 'zip'
		]);
		ALL = VIDEO.plus(AUDIO).plus(PLAYLIST, 'All Files');
	}
}
