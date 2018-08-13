package electron.ext;

import tannus.sys.GlobStar;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

@:structInit
class FileFilter {
	/* Constructor Function */
	public function new(name:String, extensions:Array<String>, ?mimes:Array<String>):Void {
		this.name = name;
		this.extensions = extensions.map(x -> x.toLowerCase().trim());
		this.mimes = mimes;
	}

/* === Instance Methods === */

    /**
      * combine [this] with [other]
      */
    public function plus(other:FileFilter, ?sumname:String):FileFilter {
        if (sumname == null)
            sumname = (name + other.name);
        var summimes = null;
        if (mimes == null && other.mimes == null) {
            summimes = null;
        }
        else {
            summimes = [];
            if (mimes != null)
                summimes = summimes.concat( mimes );

            if (other.mimes != null)
                summimes = summimes.concat( other.mimes );
            summimes = summimes.compact().unique();
        }
        return new FileFilter(sumname, extensions.concat(other.extensions), summimes);
    }

    /**
      * perform checks on mime type
      */
    public function testMime(mime: String):Bool {
        if (mimes == null) {
            return false;
        }
        else {
            var glob:GlobStar;
            for (m in mimes) {
                glob = new GlobStar(m, 'i');
                if (glob.test( mime )) {
                    return true;
                }
            }
            return false;
        }
    }

    /**
      * perform basic extension-name check
      */
    public inline function test(path : String):Bool {
        return extensions.has(path.afterLast('.').toLowerCase());
    }

/* === Instance Fields === */

	public var name : String;
	public var extensions : Array<String>;
	public var mimes : Null<Array<String>>;

/* === Static Fields === */

	public static var VIDEO : FileFilter;
	public static var AUDIO : FileFilter;
	public static var PLAYLIST : FileFilter;
	public static var IMAGE : FileFilter;
	public static var ALL : FileFilter;

	public static function __init__():Void {
		VIDEO = new FileFilter('Video Files', [
			'mp4', 'webm', 'ogv'
		], ['video/*']);

		AUDIO = new FileFilter('Audio Files', [
			'mp3', 'ogg', 'wav', 'webm'
		], ['audio/*']);

		PLAYLIST = new FileFilter('Playlist Files', [
			'm3u', 'xspf', 'pls', 'zip'
		]);

		IMAGE = new FileFilter('Image Files', [
		    'png', 'jpg', 'jpeg', 'svg', 'bmp', 'webp'
		], ['image/*']);

		ALL = VIDEO.plus(AUDIO).plus(IMAGE).plus(PLAYLIST, 'All Files');
	}
}
