package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.media.*;
import pman.db.*;
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
        duration = 0.0;
        video = null;
        audio = null;
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var duration : Float;
    public var video : Null<VideoMetadata>;
    public var audio : Null<AudioMetadata>;
}

@:structInit
class VideoMetadata {
    public var width : Int;
    public var height : Int;
}

@:structInit
class AudioMetadata {}
