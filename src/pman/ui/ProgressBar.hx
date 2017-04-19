package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.Percent;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Border;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
import gryffin.Tools.*;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class ProgressBar {
    /* Constructor Function */
    public function new(task:StandardTask<String, Dynamic>):Void {
        this.task = task;

        complete = false;
        text = '';
        progress = 0;

        this.task.onfinish.once(function() {
            complete = true;
        });
    }

/* === Instance Methods === */

    /**
      * update [this]'s data
      */
    public function update():Void {
        text = task.status;
        progress = task.completion;
    }

/* === Instance Fields === */

    public var task : StandardTask<String, Dynamic>;
    public var complete(default, null): Bool;
    public var text(default, null): String;
    public var progress(default, null): Percent;
}
