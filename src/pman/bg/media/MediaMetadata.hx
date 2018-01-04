package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.ds.tuples.*;

import pman.bg.media.*;
import pman.bg.media.MediaRow;

import haxe.Serializer;
import haxe.Unserializer;

import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaMetadata {
    /* Constructor Function */
    public inline function new(?row: MediaMetadataRow):Void {
        duration = null;
        video = null;
        audio = null;

        if (row != null) {
            pullRaw( row );
        }
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
    public inline function isEmpty():Bool {
        return (duration == null && video == null && audio == null);
    }

    /**
      * determine whether [this] metadata is missing any data
      */
    public inline function isIncomplete():Bool {
        return (
            (duration == null) ||
            //(mimeType == null) ||
            (video == null || (
                (video.width == null) ||
                (video.height == null) ||
                (video.frame_rate == null) ||
                (video.time_base == null)
            )) || 
            (audio == null || (
                (audio.channels == null) ||
                (audio.channel_layout == null)
            ))
        );
    }

    /**
      * get video framerate information
      */
    public function getVideoFrameRateInfo():Maybe<Tup2<Float, Float>> {
        if (video.frame_rate != null) {
            return video.frame_rate.split( '/' ).map( Std.parseFloat );
        }
        else {
            return null;
        }
    }

    public function clone():MediaMetadata {
        return new MediaMetadata(toRaw());
    }

/* === Instance Fields === */

    public var mimeType: Null<String>;
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

@:structInit
class ImageMetadata {
    public var width: Int;
    public var height: Int;
}
