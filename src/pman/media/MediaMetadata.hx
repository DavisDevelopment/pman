package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.ds.tuples.*;

import pman.core.*;
import pman.display.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.media.MediaType;
import pman.media.MediaSource;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class MediaMetadata {
    /* Constructor Function */
    public function new():Void {
        duration = null;
        video = null;
        audio = null;
    }

/* === Instance Methods === */

    /**
      * convert [this] to a MediaInfoRowMeta instance
      */
    public function toRaw():MediaMetadataRow {
        return {
            duration: duration,
            video: video,
            audio: audio
        };
    }

    /**
      * pull info from a MediaInfoRowMeta object
      */
    public function pullRaw(raw : MediaMetadataRow):Void {
        duration = raw.duration;
        video = untyped raw.video;
        audio = untyped raw.audio;
    }

    /**
      * determine whether [this] metadata object is void of useful data
      */
    public function isEmpty():Bool {
        return (duration == null && video == null && audio == null);
    }

    /**
      * determine whether [this] metadata is missing any data
      */
    public function isIncomplete():Bool {
        return (
            (duration == null) ||
            (video == null || (
                (video.width == null) ||
                (video.height == null) ||
                (video.frame_rate == null) ||
                (video.time_base == null)
            )) || 
            (audio == null)
        );
    }

    public function getVideoFrameRateInfo():Maybe<Tup2<Float, Float>> {
        if (video.frame_rate != null) {
            return video.frame_rate.split( '/' ).map( Std.parseFloat );
        }
        else {
            return null;
        }
    }

/* === Instance Fields === */

    public var duration : Null<Float>;
    public var video : Null<VideoMetadata>;
    public var audio : Null<AudioMetadata>;
}

@:structInit
class VideoMetadata {
    public var width : Int;
    public var height : Int;
    @:optional public var frame_rate : String;
    @:optional public var time_base : String;
}

@:structInit
class AudioMetadata {
    public var channels: Int;
    public var channel_layout: String;
}
