package pman.events;

import tannus.ds.AnonTools;

class Event {
    /* Constructor Function */
    public function new() {
        //initialize variables
        type = 'event';
        timeStamp = Date.now().getTime();
        cancelable = false;
        defaultPrevented = false;
        cancelled = false;
        target = originalTarget = null;
    }

/* === Instance Methods === */

    public function cancel() {
        if ( cancelable ) {
            cancelled = true;
        }
    }

    public function preventDefault() {
        defaultPrevented = true;
    }

    public function copy():Event {
        return AnonTools.deepCopy(this);
    }

    public function retarget(newTarget:Dynamic):Event {
        var res:Event = copy();
        res.target = newTarget;
        return res;
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var type(default, null): String;
    public var timeStamp(default, null): Float;
    public var cancelable(default, null): Bool;
    public var defaultPrevented(default, null): Bool;
    public var cancelled(default, null): Bool;
    public var target(default, null): Dynamic;
    public var originalTarget(default, null): Dynamic;
}
