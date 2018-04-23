package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaSource;

import Slambda.fn;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;

enum TypedMediaMetadata {
    TMVideo(video: BaseVideoMeta);
    TMImage(image: BaseImageMeta);
    TMAudio(audio: BaseAudioMeta);
    
    TMMusic(music: BaseMusicMeta);
    TMMovie(movie: BaseMovieMeta);
    TM3XMovie(movie: AMovieMeta);
}

typedef JsonTypedMediaMetadata = {
    ?vi: BaseVideoMeta,
    ?im: BaseImageMeta,
    ?au: BaseAudioMeta,
    ?mu: BaseMusicMeta,
    ?mo: BaseMovieMeta,
    ?am: AMovieMeta
};

typedef BaseMeta <Format:BaseFormatInfo> = {
    format: Format
};

typedef BaseMusicMeta = {
    >BaseAudioMeta,

    title: String,
    ?images: Array<MusicMetaImageType>,
    ?artist: String,
    ?album: String,
    ?year: Int,
    ?track_index: Int
};

typedef BaseMovieMeta = {
    >BaseVideoMeta,

    title: String
};

typedef AMovieMeta = {
    >BaseMovieMeta,

    ?iteration: Int,
    ?scene: Int,
    ?origin: {?host:String, ?uri:String, ?id:Array<Dynamic>}
};

typedef BaseVideoMeta = {
    >BaseMeta<VideoFormatInfo>,
    >BaseVisualMeta,
    >BasePlayableMeta,

};

typedef BaseImageMeta = {
    >BaseMeta<ImageFormatInfo>,
    >BaseVisualMeta,

};

typedef BaseVisualMeta = {
    width: Int,
    height: Int,
    display_aspect_ratio: Array<Int>
};

typedef BasePlayableMeta = {
    duration: Float
};

typedef BaseAudioMeta = {
    >BaseMeta<AudioFormatInfo>,
    >BasePlayableMeta,

    channel_count: Int,
    channel_layout: String,
    sample_rate: Int,
    bits_per_sample: Int
};

typedef BaseFormatInfo = {
    name: String,
    long_name: String
};

typedef ImageFormatInfo = {
    >BaseFormatInfo,

    image_type: ImageFormatType,
    codec: ImageCodecInfo
};

typedef VideoFormatInfo = {
    >BaseFormatInfo,

    video: VideoCodecInfo,
    ?audio: AudioCodecInfo
};

typedef AudioFormatInfo = {
    >BaseFormatInfo,

    codec: AudioCodecInfo
};

typedef AudioCodecInfo = {
    >CodecInfo,

};

typedef VideoCodecInfo = {
    >CodecInfo,

    frame_rate: String,
    time_base: String,
    fps: Int
};

typedef ImageCodecInfo = {
    >VisualCodecInfo,

    animated: Bool
};

typedef VisualCodecInfo = {
    >CodecInfo,

    color_space: String,
    // usually either 3 or 4
    color_channels: Int
};

typedef CodecInfo = {
    type: String,
    name: String,
    ?long_name: String,
    ?tag: String,
    ?time_base: String
};

//typedef CodecInfo = {
    //codec_name: String,
    //codec_long_name: String,
    //codec_type: String,
    //codec_tag: String,
    //codec_time_base: String
//}

@:enum
abstract ImageFormatType (Int) from Int to Int {
    var BITMAP = 0;
    var VECTOR = 1;
}

/*
   information taken from [id3 tag format specification page](http://id3.org/id3v2.3.0#Attached_picture)
   this list is not exhaustive, only the img types that I think we're actually likely to use are included
*/
@:enum
abstract MusicMetaImageType (Int) from Int to Int {
    var ICON = 0x01;
    var ALTICON = 0x02;
    var COVER_FRONT = 0x03;
    var COVER_BACK = 0x04;
    var ARTIST = 0x08;
}
