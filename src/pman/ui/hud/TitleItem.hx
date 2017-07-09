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

class TitleItem extends TextualHUDItem {
    /* Constructor Function */
    public function new(hud : PlayerHUD):Void {
        super( hud );

        tb.fontFamily = 'Ubuntu';
        tb.fontSize = 20;
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

        if (player.track != null) {
            var t = player.track;

            tb.text = t.title;
        }
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
    }

    override function shouldRenderText():Bool return (super.shouldRenderText() && player.track != null);

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        var hr = hud.rect;

        super.calculateGeometry( r );
        x = (hr.x + margin);
        y = (hr.y + margin);
    }

    /**
      * get whether [this] is enabled
      */
    override function getEnabled():Bool {
        var mrs = player.getMostRecentOccurrenceTime( 'change:nowPlaying' );
        if (mrs == null) {
            return false;
        }
        else {
            return ((now - mrs.getTime()) <= duration);
        }
    }
}
