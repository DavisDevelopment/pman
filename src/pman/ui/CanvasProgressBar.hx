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

class CanvasProgressBar extends Ent {
    /* Constructor Function */
    public function new(task:Trackable<Dynamic>, ?player:Player):Void {
        super();

        this.task = task;
        border = new Border(3, null, 3);
        pb = new ProgressBar( task );
        tb = new TextBox();
        tb.color = new Color(255, 255, 255);
        tb.fontFamily = 'Ubuntu';
        tb.fontSizeUnit = 'px';

        if (player == null) {
            player = BPlayerMain.instance.player;
        }
        this.player = player;
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        super.init( stage );

        task.onResult.once(function(x) {
            delete();
        });
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
        var cols = getColors();

        c.save();

        // draw the background
        c.beginPath();
        c.fillStyle = cols[0];
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.fill();

        // draw the hilited area
        c.beginPath();
        c.fillStyle = cols[2];
        c.rect(x, y, (pb.progress.of( w )), h);
        c.closePath();
        c.fill();

        c.drawComponent(tb, 0, 0, tb.width, tb.height, x, y, tb.width, tb.height);

        // draw the border
        c.beginPath();
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.stroke();

        c.restore();
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        var cols = getColors();
        border.color = cols[1];

        if ( pb.complete ) {
            delete();
        }
        pb.update();

        tb.text = pb.text;
        tb.fit(w, h);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        super.calculateGeometry( r );

        var vp = player.view.rect;
        w = (vp.width * 0.8);
        h = 30;
        centerX = vp.centerX;
        centerY = vp.centerY;
    }

    /**
      * get [this]'s colors
      */
    private function getColors():Array<Color> {
        var t = player.theme;
        if (colors == null) {
            var cols = [t.primary, t.secondary, t.secondary.darken( 30 )];
            colors = cols.map( t.save );
            return cols;
        }
        else {
            return colors.map( t.restore );
        }
    }

/* === Instance Fields === */

    public var player : Player;
    public var task : Trackable<Dynamic>;
    public var pb : ProgressBar;
    public var border : Border;
    public var tb : TextBox;

    private var colors : Null<Array<Int>> = null;
}
