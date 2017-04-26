package pman.time;

import tannus.html.Win;
import tannus.io.Signal;
import tannus.math.TMath.*;

import Date.now as cdate;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using Slambda;

class AnimTicker {
    /* Constructor Function */
    public function new():Void {
        onTick = new Signal();
    }

/* === Instance Methods === */

    /**
      * start [this] ticker
      */
    public function start():Void {
        var win = Win.current;
        _stopped = false;
        function _tick(n : Float):Void {
            if (!_stopped) {
                onTick.call( n );
                frameId = win.requestAnimationFrame( _tick );
            }
        }
        frameId = win.requestAnimationFrame( _tick );
    }

    /**
      * stop [this] ticker
      */
    public function stop():Void {
        var win = Win.current;
        if (frameId != null) {
            win.cancelAnimationFrame( frameId );
        }
        _stopped = true;
    }

/* === Instance Fields === */

    public var onTick : Signal<Float>;

    private var frameId : Null<Int> = null;
    private var _stopped : Bool = false;
}
