package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.Percent;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Border;

import pman.async.Trackable;
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
    public function new(task:Trackable<Dynamic>):Void {
        this.task = task;

        complete = false;
        text = '';
        progress = 0;

        task.onComplete.once(function(res) {
            complete = true;
        });
    }

/* === Instance Methods === */

    /**
      * update [this]'s data
      */
    public function update():Void {
        text = task.statusMessage;
        progress = new Percent( task.progress );
    }

/* === Instance Fields === */

    public var task : Trackable<Dynamic>;
    public var complete(default, null): Bool;
    public var text(default, null): String;
    public var progress(default, null): Percent;
}
