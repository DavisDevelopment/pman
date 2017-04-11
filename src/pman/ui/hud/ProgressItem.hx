package pman.ui.hud;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
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

class ProgressItem extends PlayerHUDItem {
    /* Constructor Function */
    public function new(hud : PlayerHUD):Void {
        super( hud );
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if (enabled && player.session.hasMedia()) {
            var p:Percent = Percent.percent(player.currentTime, player.durationTime);
            var cx:Float = (x + p.of( w ));

            c.save();

            c.strokeStyle = 'white';
            c.lineWidth = 2.0;

            c.beginPath();
            c.drawRect( rect );
            c.closePath();
            c.stroke();

            c.lineWidth = 3.5;
            c.beginPath();
            c.moveTo(cx, y);
            c.lineTo(cx, (y + h));
            c.stroke();
            
            c.restore();
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        var hr = hud.rect;

        h = 30;
        x = margin;
        y = (hr.y + hr.h - h - margin);
        w = (hr.w - (margin * 2) - (h + (margin * 2)));

        super.calculateGeometry( r );
    }

    /**
      * get whether [this] is enabled
      */
    override function getEnabled():Bool {
        var mrs = player.getMostRecentOccurrenceTime( 'seek' );
        if (mrs == null) {
            return false;
        }
        else {
            return ((now - mrs.getTime()) <= duration);
        }
    }
}
