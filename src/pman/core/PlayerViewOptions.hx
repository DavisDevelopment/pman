package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.graphics.Color;

import pman.display.VideoFilter;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.IteratorTools;

class PlayerViewOptions extends EventDispatcher {
    /* Constructor Function */
    public function new():Void {
        super();
        __checkEvents = false;

        videoFilter = null;
        videoFilterRaw = true;
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var videoFilter : Null<VideoFilter>;
    public var videoFilterRaw : Bool;
}
