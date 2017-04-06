package ffmpeg;

import tannus.node.*;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

@:jsRequire( 'fluent-ffmpeg' )
extern class FFfmpeg extends EventEmitter {
    /* Constructor Function */
    public function new(src : String):Void;

/* === Instance Methods === */

    public function input(src : String):Void;
    public function addInput(src : String):Void;
    public function mergeAdd(src : String):Void;

    public function size(size : String):Void;
    public function videoSize(size : String):Void;
    public function withSize(size : String):Void;

    public function screenshots(options:ScreenshotOptions):Void;
    inline public function onFileNames(f : Array<String>->Void):FFfmpeg {
        return untyped this.on('filenames', f);
    }

    //@:overload(function(n:String,f:Function):FFfmpeg {})
    //override function on(name:String, f:Function):Void;

    //@:overload(function(n:String,f:Function):FFfmpeg {})
    //override function once(name:String, f:Function):Void;

    inline function onEnd(f : Void->Void):FFfmpeg {
        return untyped on('end', f);
    }

/* === Instance Fields === */

/* === Static Methods === */

    public static function setFfmpegPath(path:String):Void;
    public static function setFfprobePath(path:String):Void;
    public static function setFlvtoolPath(path:String):Void;

    public static function ffprobe(src:String, callback:Null<Dynamic>->ProbeResults->Void):Void;
}

typedef ProbeResults = {
    var streams : Array<StreamInfo>;
    var format : FormatInfo;
};

typedef StreamInfo = Dynamic;
typedef FormatInfo = Dynamic;

typedef ScreenshotOptions = {
    ?folder : String,
    ?filename : String,
    ?count : Int,
    ?timemarks : Array<Time>,
    ?timestamps : Array<Time>,
    ?size : String
};

typedef Time = EitherType<Float, String>;
