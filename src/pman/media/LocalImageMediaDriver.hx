package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.display.Image;

import pman.display.*;
import pman.media.PlaybackCommand;
import pman.bg.media.Dimensions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class LocalImageMediaDriver extends MediaDriver {
    /* Constructor Function */
    public function new(img: Image):Void {
        super();

        i = img;
    }

/* === Instance Methods === */

    override function getSource():String return i.src;
    override function getDimensions():Dimensions return new Dimensions(i.width, i.height);

    override function getLoadSignal():VoidSignal {
        var sig = new VoidSignal();
        i.ready.on( sig.fire );
        return sig;
    }

    override function dispose():Void {
        super.dispose();

        i = null;
    }

/* === Instance Fields === */

    public var i: Image;
}
