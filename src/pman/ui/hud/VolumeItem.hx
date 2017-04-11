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

class VolumeItem extends PlayerHUDItem {
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

        if ( enabled ) {
            c.save();
            c.strokeStyle = 'white';
            c.lineWidth = 2.0;

            c.beginPath();
            c.drawRect( rect );
            c.closePath();
            c.stroke();

            var p:Percent = Percent.percent(player.volume, 1.0);
            p = p.complement();
            var cy:Float = (y + p.of( h ));

            c.beginPath();
            c.moveTo(x, cy);
            c.lineTo((x + w), cy);
            c.stroke();
            c.restore();
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        var hr = hud.rect;

        w = 30;
        x = (hr.x + hr.w - margin - w);
        h = (hr.h * 0.7);
        y = (hr.y + hr.h - h - margin);

        super.calculateGeometry( r );
    }

    /**
      * get whether [this] is enabled
      */
    override function getEnabled():Bool {
        var mrs = player.getMostRecentOccurrenceTime( 'change:volume' );
        if (mrs == null) {
            return false;
        }
        else {
            return ((now - mrs.getTime()) <= duration);
        }
    }
}
