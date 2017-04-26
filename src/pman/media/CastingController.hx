package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import electron.Tools.*;

import pman.core.*;
import pman.display.*;
import pman.media.PlaybackCommand;
import pman.async.*;
import pman.Errors.*; 

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class CastingController<Status> {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    public function tick():Void {

    }

    public function attach(player:Player, done:VoidCb):Void {
        defer(done.bind());
    }

    public function detach(player:Player, done:VoidCb):Void {
        defer(done.bind());
    }

    public function getStatus(done : Cb<Status>):Void {
        done(null, null);
    }

/* === Instance Fields === */
}
