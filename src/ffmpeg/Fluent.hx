package ffmpeg;

import tannus.node.*;

import haxe.Constraints.Function;
import haxe.extern.EitherType;
import haxe.extern.EitherType as Either;
import haxe.extern.Rest;

import pman.async.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:jsRequire( 'fluent-ffmpeg' )
extern class Fluent extends EventEmitter {
    /* Constructor Function */
    public function new(src : String):Void;

/* === Instance Methods === */

    public function input(src : String):Void;
    public function addInput(src : String):Void;
    public function mergeAdd(src : String):Void;

    public function inputOption(option : Either<String, Array<String>>):Void;
    public function inputOptions(options : Rest<String>):Void;
    public function addInputOption(option : Either<String, Array<String>>):Void;

    public function size(size : String):Void;
    public function videoSize(size : String):Void;
    public function withSize(size : String):Void;
    public function renice(niceness : Int = 0):Void;

    //public function videoFilter(filters:Either<String, {
        //filter: String,
        //options: Either<String, Either<Array<Dynamic>, Dynamic>>
    //}>):Void;

    @:overload(function(filter : Rest<String>):Void {})
    @:overload(function(filter : Array<String>):Void {})
    public function videoFilter(filter_o : Rest<{filter: String, options:Dynamic}>):Void;

    public function fps(rate : Float):Void;
    public function aspect(aspect : Either<String, Float>):Void;
    public function autopad(?color:String):Void;
    public function output(dest:Either<String, WritableStream>):Void;
    public function duration(time : Float):Void;
    public function seek(time : Float):Void;
    public function format(outputFormat : String):Void;
    public function run():Void;
    public function execute():Void;
    public function save(path : String):Void;

    public function screenshots(options:ScreenshotOptions):Void;
    inline public function onFileNames(f : Array<String>->Void):FFfmpeg {
        return untyped this.on('filenames', f);
    }
    inline public function onProgress(f : FfmpegProgressEvent->Void):FFfmpeg {
        return untyped this.on('progress', f);
    }

    inline function onEnd(f : Void->Void):FFfmpeg {
        return untyped on('end', f);
    }
    inline function onError(f : Dynamic->Buffer->Buffer->Void):FFfmpeg return untyped on('error', f);

/* === Instance Fields === */

/* === Static Methods === */

    public static function setFfmpegPath(path:String):Void;
    public static function setFfprobePath(path:String):Void;
    public static function setFlvtoolPath(path:String):Void;

    @:native('ffprobe')
    public static function _ffprobe(src:String, callback:Null<Dynamic>->ProbeResults->Void):Void;
    public static inline function probe(src:String, done:Cb<ProbeResults>):Void {
        _ffprobe(src, untyped done);
    }

    // wrap that shit
    public static inline function ffmpeg(src : String):Fluent {
        FluentTools._gather();
        return new Fluent( src );
    }
}

@:forward
abstract ProbeResults (RawProbeResults) from RawProbeResults {
    public inline function new(x : RawProbeResults) {
        this = x;
    }

    public function hasVideo():Bool {
        return (videoStreams.length > 0);
    }
    public function hasAudio():Bool {
        return (audioStreams.length > 0);
    }

    public var videoStreams(get, never):Array<StreamInfo>;
    private function get_videoStreams() {
        if (this.videoStreams == null) {
            this.videoStreams = this.streams.filter.fn(_.codec_type == 'video');
        }
        return this.videoStreams;
    }

    public var audioStreams(get, never):Array<StreamInfo>;
    private function get_audioStreams() {
        if (this.audioStreams == null) {
            this.audioStreams = this.streams.filter.fn(_.codec_type == 'audio');
        }
        return this.audioStreams;
    }
}

typedef RawProbeResults = {
    streams: Array<StreamInfo>,
    format: FormatInfo,

    ?videoStreams: Array<StreamInfo>,
    ?audioStreams: Array<StreamInfo>
};

typedef RawFormatInfo = {
    filename: String,
    nb_streams: Int,
    nb_programs: Int,
    format_name: String,
    format_long_name: String,
    start_time: String,
    duration: Float,
    size: Int,
    bit_rate: Int,
    probe_score: Int
};

typedef RawStreamInfo = {
    index: Int,
    codec_name: String,
    codec_long_name: String,
    profile: String,
    codec_type: String,
    codec_time_base: String,
    codec_tag: String,
    level: Int,
    r_frame_rate: String,
    avg_frame_rate: String,
    time_base: String,
    bit_rate: Int,
    duration: Float,
    duration_ts: Int,
    max_bit_rate: Int,
    nb_frames: Int,

/* -- media-type-specific properties -- */

    // Video
    ?width: Int,
    ?height: Int,
    ?coded_width: Int,
    ?coded_height: Int,
    ?pix_fmt: String,

    // Audio
    ?sample_fmt: String,
    ?sample_rate: Int,
    ?channels: Int,
    ?channel_layout: String,
    ?bits_per_sample: Int
};

@:forward
abstract FormatInfo (RawFormatInfo) {
    public inline function new(rfi : RawFormatInfo) {
        this = rfi;
    }
}

@:forward
abstract StreamInfo (RawStreamInfo) from RawStreamInfo {
    public inline function new(rsi : RawStreamInfo) {
        this = rsi;
    }
}

typedef ScreenshotOptions = {
    ?folder : String,
    ?filename : String,
    ?count : Int,
    ?timemarks : Array<Time>,
    ?timestamps : Array<Time>,
    ?size : String
};

typedef Time = EitherType<Float, String>;
typedef FfmpegProgressEvent = {
    frames: Int,
    currentFps: Float,
    currentKbps: Float,
    targetSize: Float,
    timemark: Float,
    percent: Float
};
