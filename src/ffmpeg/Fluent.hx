package ffmpeg;

import tannus.io.*;
import tannus.ds.*;
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
using tannus.async.Asyncs;

@:jsRequire( 'fluent-ffmpeg' )
extern class Fluent extends EventEmitter {
    /* Constructor Function */
    public function new(src : String):Void;

/* === Instance Methods === */

    public function input(src : String):Void;
    public function addInput(src : String):Void;
    public function mergeAdd(src : String):Void;

    public function inputFormat(format: String):Void;
    public function fromFormat(format: String):Void;
    public function withInputFormat(format: String):Void;

    public function inputFps(fps: Float):Void;
    public function nativeFrameRate():Void;
    //public function seekInput(time:Either<String, Float>):Void;
    public function loop(duration: Either<String, Float>):Void;
    
    public function noAudio():Void;
    public function audioCodec(codec: String):Void;
    public function audioBitrate(rate: Float):Void;
    public function audioChannels(count: Int):Void;
    public function audioFrequency(freqHz: Float):Void;
    public function audioQuality(q: Float):Void;
    
    @:overload(function<T:AudioFilterArg>(filters: Array<T>):Void {})
    public function audioFilters<T:AudioFilterArg>(filters: Rest<T>):Void;

    @:overload(function<T:AudioFilterArg>(filters: Array<T>):Void {})
    public function audioFilter<T:AudioFilterArg>(filter: Rest<T>):Void;

    public function inputOption(option : Either<String, Array<String>>):Void;
    public function inputOptions(options : Rest<String>):Void;
    public function addInputOption(option : Either<String, Array<String>>):Void;
    public function setStartTime(time: Time):Void;
    public function seekInput(time: Time):Void;

    public function size(size : String):Void;
    public function videoSize(size : String):Void;
    public function withSize(size : String):Void;

    public function renice(niceness : Int = 0):Void;

    @:overload(function<T:VideoFilterArg>(filters: Array<T>):Void {})
    public function videoFilters<T:VideoFilterArg>(filters: Rest<T>):Void;

    @:overload(function<T:VideoFilterArg>(filters: Array<T>):Void {})
    public function videoFilter<T:VideoFilterArg>(filter: Rest<T>):Void;

    public function noVideo():Void;
    public function videoCodec(codec: String):Void;
    public function videoBitrate(bitrate:Float, ?constant:Bool):Void;

    public function fps(rate : Float):Void;
    public function autopad(?color:String):Void;
    public function frames(count: Int):Void;
    public function takeFrames(count: Int):Void;
    public function aspect(aspect : Either<String, Float>):Void;
    public function setAspectRatio(aspect: Either<String,Float>):Void;
    public function keepPixelAspect():Void;
    public function keepDisplayAspectRatio():Void;
    public function duration(time : Time):Void;
    public function setDuration(time: Time):Void;
    public function seek(time : Float):Void;
    public function seekOutput(time: Float):Void;
    public function format(outputFormat : String):Void;
    public function outputFormat(format: String):Void;
    public function toFormat(format: String):Void;

    @:overload(function(options: Array<String>):Void {})
    @:overload(function(tokens: Rest<String>):Void {})
    public function outputOptions(singleOption: String):Void;

    @:overload(function<T:ComplexFilterArg>(filters: Array<T>):Void {})
    public function complexFilter<T:ComplexFilterArg>(filters: Rest<T>):Void;

    @:overload(function(stream:Either<Duplex,Writable>, ?options:Dynamic):Void {})
    public function output(outputPath: String):Void;

    @:overload(function(stream:Either<Duplex,Writable>, ?options:Dynamic):Void {})
    public function addOutput(outputPath: String):Void;

    public function pipe(?stream:Either<Writable,Duplex>, ?options:Dynamic):Null<PassThrough>;
    public function stream(?stream:Either<Writable,Duplex>, ?options:Dynamic):Null<PassThrough>;
    public function writeToStream(?stream:Either<Writable,Duplex>, ?options:Dynamic):Null<PassThrough>;

    public function run():Void;
    public function execute():Void;

    public function save(path : String):Void;

    public function mergeToFile(filename:String, tmpDir:String):Void;

    public function screenshots(options:ScreenshotOptions):Void;

    inline public function onFileNames(f : Array<String>->Void):FFfmpeg { return untyped this.on('filenames', f); }
    inline public function onProgress(f : FfmpegProgressEvent->Void):FFfmpeg { return untyped this.on('progress', f); }

    inline function onEnd(f : Void->Void):FFfmpeg { return untyped on('end', f); }
    inline function onError(f : Dynamic->Buffer->Buffer->Void):FFfmpeg return untyped on('error', f);

/* === Instance Fields === */

/* === Static Methods === */

    public static function setFfmpegPath(path:String):Void;
    public static function setFfprobePath(path:String):Void;
    public static function setFlvtoolPath(path:String):Void;

    @:native('getAvailableFormats')
    public static function _getAvailableFormats(callback: Cb<Dynamic<AvailFormatInfo>>):Void;
    public static inline function getAvailableFormats():Promise<Anon<AvailFormatInfo>> {
        return cast _getAvailableFormats.toPromise();
    }

    @:native('getAvailableCodecs')
    public static function _getAvailableCodecs(callback: Cb<Dynamic<AvailCodecInfo>>):Void;
    public static inline function getAvailableCodecs():Promise<Anon<AvailCodecInfo>> {
        return cast _getAvailableCodecs.toPromise();
    }

    @:native('ffprobe')
    public static function _ffprobe(src:String, callback:Null<Dynamic>->ProbeResults->Void):Void;
    public static inline function probe(src:String, done:Cb<ProbeResults>):Void {
        FluentTools._gather();
        _ffprobe(src, untyped done);
    }

    // wrap that shit
    public static inline function ffmpeg(src : String):Fluent {
        FluentTools._gather();
        return new Fluent( src );
    }
}

typedef AvailFormatInfo = {
    description: String,
    canMux: Bool,
    canDemux: Bool
};
typedef AvailCodecInfo = {
    description: String,
    canEncode: Bool,
    canDecode: Bool,

    type: CodecType,
    intraFrameOnly: Bool,
    isLossy: Bool,
    isLossless: Bool
};

@:enum
abstract CodecType (String) from String to String {
    var AudioCodec = 'audio';
    var VideoCodec = 'video';
    var Subtitle = 'subtitle';
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

typedef AudioFilter = {
    filter: String,
    ?options: Either<String, Either<Array<Dynamic>, Dynamic>>
};
typedef AudioFilterArg = Either<String, AudioFilter>;

typedef VideoFilter = {
    filter: String,
    ?options: Either<String, Either<Array<Dynamic>, Dynamic>>
};
typedef VideoFilterArg = Either<String, VideoFilter>;

typedef ComplexFilter = {
    filter: String,
    ?options: Either<String, Either<Array<Dynamic>, Dynamic>>,
    ?inputs: Either<String, Array<String>>,
    ?outputs: Either<String, Array<String>>
};
typedef ComplexFilterArg = Either<String, ComplexFilter>;
