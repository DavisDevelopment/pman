package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
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
    public function toRaw():MediaInfoRowMeta {
        return {
            duration: duration,
            video: video,
            audio: audio
        };
    }

    /**
      * pull info from a MediaInfoRowMeta object
      */
    public function pullRaw(raw : MediaInfoRowMeta):Void {
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
            (video == null) || 
            (audio == null)
        );
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
}

@:structInit
class AudioMetadata {
    public var channels: Int;
    public var channel_layout: String;
}
