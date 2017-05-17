package pman.ui.statusbar;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.media.*;
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

class DefaultStatusBarItem extends StatusBarItem {
    /* Constructor Function */
    public function new():Void {
        super();

        duration = -1;
        tb = new TextBox();
        tb.fontFamily = 'Ubuntu';
        tb.fontSizeUnit = 'px';
        tb.fontSize = 15;
        tb.color = new Color(255, 255, 255);
    }

/* === Instance Methods === */

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        var tbr = new Rectangle(0, 0, tb.width, tb.height);
        tbr.centerY = centerY;
        tbr.x = 0;

        c.drawComponent(tb, 0, 0, tb.width, tb.height, tbr.x, tbr.y, tbr.w, tbr.h);
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        var oldText = tb.text;
        if (player.track == null) {
            tb.text = '';
        }
        else {
            switch ( player.track.source ) {
                case MediaSource.MSLocalPath( path ):
                    tb.text = path;
                case MediaSource.MSUrl( url ):
                    tb.text = url;
            }
        }

        if (oldText != tb.text) {
            tb.autoScale(null, rect.h);
        }
    }

/* === Instance Fields === */

    private var tb : TextBox;
}
