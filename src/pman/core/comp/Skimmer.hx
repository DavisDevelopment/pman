package pman.core.comp;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import pman.core.*;
import pman.media.*;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;
using pman.media.MediaTools;

class Skimmer extends PlayerComponent {
    /* Constructor Function */
    public function new():Void {
        super();

        r = new Random();
        ranges = null;
        currentRange = null;
    }

/* === Instance Methods === */

    /**
      * on each frame
      */
    override function onTick(time : Float):Void {
        if (player.track != null && currentRange != null) {
            if (ceil(player.currentTime) >= currentRange.end) {
                var nextRange = ranges.shift();
                if (nextRange == null) {
                    detach();
                }
                else {
                    currentRange = nextRange;
                    player.currentTime = ceil(nextRange.start);
                    trace( currentRange );
                }
            }
            else if (!currentRange.contains( player.currentTime )) {
                player.currentTime = currentRange.start;
            }
        }
    }

    /**
      * when the Track is ready
      */
    override function onTrackReady(track : Track):Void {
        if (track.data != null) {
            ranges = getRanges( track );
            currentRange = ranges.shift();
        }
        else {
            ranges = null;
            currentRange = null;
        }

        if (currentRange != null) {
            player.currentTime = ceil(currentRange.start);
        }
    }

    /**
      * when the Track has changed
      */
    override function onTrackChanged(delta : Delta<Null<Track>>):Void {
        var newTrack:Null<Track> = delta.current;
        if (delta.previous != null) {
            detach();
        }
    }

    /**
      * get the current TimeRange
      */
    private function getCurrentRange_():Maybe<TimeRange> {
        if (ranges == null) {
            return null;
        }
        else {
            var time = player.currentTime;
            for (range in ranges) {
                if (range.contains( time )) {
                    return range;
                }
            }
            return null;
        }
    }

    /**
      * build random list of time ranges from the given Track
      */
    private function getRanges(t : Track):Null<TimeRanges> {
        var result:Array<TimeRange> = new Array();
        var min = 10.0;
        var max = 45.0;
        var total = t.data.meta.duration;
        if (total == null) {
            return null;
        }
        result = [new TimeRange(0.0, total)];
        function noneTooLong():Bool {
            return !result.any.fn(_.length > max);
        }
        while (!noneTooLong()) {
            var tmp = result;
            result = [];
            for (tr in tmp) {
                var trl = tr.split(r.randfloat(min, max));
                result = result.concat( trl );
            }
        }
        r.ishuffle( result );
        return new TimeRanges( result );
    }

/* === Instance Fields === */

    public var r : Random;
    public var ranges : Null<TimeRanges>;
    public var currentRange : Null<TimeRange>;
}
