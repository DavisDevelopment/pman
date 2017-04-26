package pman.time;

import tannus.io.VoidSignal;
import tannus.math.TMath.*;

import Date.now as cdate;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using Slambda;

class Timer {
    /* Constructor Function */
    public function new(duration : Float):Void {
        this.duration = duration;
        this.onInterval = new VoidSignal();
        this.lastTime = null;
    }

/* === Instance Methods === */

    public function tick():Void {
        var now = now();
        if (lastTime == null) {
            onInterval.fire();
            lastTime = now;
        }
        else {
            if ((now - lastTime) >= duration) {
                onInterval.fire();
                lastTime = now;
            }
        }
    }

    private inline function now():Float return cdate().getTime();

/* === Instance Fields === */

    public var duration(default, null): Float;
    public var onInterval:VoidSignal;
    private var lastTime : Null<Float>;
}
