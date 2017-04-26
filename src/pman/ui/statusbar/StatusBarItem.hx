package pman.ui.statusbar;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

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

class StatusBarItem extends Ent {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * [this] has been attached to the status bar
      */
    public function attached(sb : PlayerStatusBar):Void {
        statusBar = sb;
    }

    /**
      * initialize [this] StatusBar item
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * update [this] StatusBar item
      */
    override function update(stage : Stage):Void {
        super.update( stage );
    }

    /**
      * render [this] StatusBar item
      */
    override function render(stage:Stage, c:Ctx):Void {
        null;
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        rect.cloneFrom( r );
    }

/* === Instance Fields === */

    public var duration : Float;
    public var statusBar : PlayerStatusBar;
}
