package pman.tools.mp4box;

import tannus.io.*;

import tannus.node.Buffer;

import js.html.ArrayBuffer;
import js.html.Int32Array;

@:jsRequire('mp4box', 'MP4Box')
extern class MP4Box {
    public function new():Void;

    public dynamic function onError(error : Dynamic):Void;
    public dynamic function onReady(info : MP4Metadata):Void;
    public dynamic function onMoovStart():Void;
    public dynamic function onSamples(track_id:Int, user:Dynamic, samples:Array<MP4SampleInfo>):Void;

    public function flush():Void;
    public function getInfo():MP4Metadata;
    public function start():Void;
    public function stop():Void;
    public function seek(time:Float, useRap:Bool):Int;

    @:native('appendBuffer')
    public function appendArrayBuffer(ab : ArrayBuffer):Int;
    inline public function appendBuffer(buffer : Buffer):Int {
        return appendArrayBuffer( buffer.buffer );
    }
    inline public function appendBytes(bytes : ByteArray):Int return appendBuffer(bytes.getData());
}

typedef MP4Info = {
    hasMoov: Bool,
    brands: Array<String>,
    created: Date,
    modified: Date,
    timescale: Int,
    duration: Int,
    isProgressive: Bool,
    isFragmented: Bool,
    fragment_duration: Int,
    hasIOD: Bool,
    tracks: Array<MP4TrackInfo>,
    videoTracks: Array<MP4TrackInfo>,
    audioTracks: Array<MP4TrackInfo>
};

typedef MP4TrackInfo = {
    id: Int,
    created: Date,
    modified: Date,
    alternate_group: Int,
    timescale: Int,
    duration: Int,
    bitrate: Int,
    nb_samples: Int,
    codec: String,
    language: String,
    track_width: Int,
    track_height: Int,
    layer: Int,
    matrix: Int32Array,
    ?video: MP4TrackVideoInfo,
    ?audio: MP4TrackAudioInfo
};

typedef MP4TrackVideoInfo = {
    width: Int,
    height: Int
};

typedef MP4TrackAudioInfo = {
    sample_rate: Int,
    channel_count: Int,
    sample_size: Int
};

typedef MP4SampleInfo = {
    track_id: Int,
    description: String,
    is_rap: Bool,
    timescale: Int,
    dts: Int,
    cts: Int,
    duration: Int,
    size: Int,
    data: ArrayBuffer
};
