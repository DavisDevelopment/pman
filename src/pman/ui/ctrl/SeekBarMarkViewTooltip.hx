package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.events.*;
import tannus.events.Key;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.*;
import gryffin.ui.Border;

import electron.ext.*;
import electron.ext.Menu;
import electron.ext.MenuItem;

import pman.core.*;
import pman.media.*;
import pman.media.info.Mark;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.async.SeekbarPreviewThumbnailLoader as ThumbLoader;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class SeekBarMarkViewTooltip {
    /* Constructor Function */
    public function new(mv : SeekBarMarkView):Void {
        markView = mv;

        tb = [new TextBox(), new TextBox()];
        tbr = new Array();
        border = new Border(3.0, player.theme.primary.lighten( 20 ), 3.0);
    }

/* === Instance Methods === */

    /**
      * Paint [this]
      */
    public function paint(c:Ctx, x:Float, y:Float):Void {
        var colors = getColors();

        update(colors, x);

        c.beginPath();
        c.fillStyle = colors[1];
        c.drawRoundRect(rect, 3.0);
        c.closePath();
        c.fill();

        c.beginPath();
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.stroke();

        for (index in 0...tb.length) {
            var t = tb[index];
            var r = tbr[index];
            c.drawComponent(t, 0, 0, t.width, t.height, r.x, r.y, r.w, r.h);
        }
    }

    /**
      * update [this]
      */
    public function update(colors:Array<Color>, x:Float):Void {
        ttr = new Rectangle();
        for (t in tb) {
            t.color = colors[0];
            t.fontSizeUnit = 'px';

            ttr.width = max(ttr.width, t.width);
            ttr.height += t.height;
        }
        var t = tb[0];
        t.text = markView.name;
        t.fontSize = 12;
        t = tb[1];
        t.text = markView.key().name;
        t.fontSize = 12;

        var mvl = @:privateAccess markView.bar.markViews;
        var prev = mvl[mvl.indexOf(markView)-1];
        if (prev != null && rect != null && rect.containsRect( prev.tooltip.rect )) {
            yOffset = (prev.tooltip.rect.h + prev.tooltip.yOffset + margin);
            var tempy = yOffset;
            yOffset = 0.0;
            rect.y = (bar.controls.y - rect.height - margin - yOffset);
            if (!rect.containsRect( prev.tooltip.rect )) {
                yOffset = 0.0;
            }
            else {
                yOffset = tempy;
            }
        }

        inline function dbl(x:Float):Float return (x * 2);

        rect = new Rectangle(0, 0, (ttr.width + dbl( margin )), (ttr.height + margin));
        rect.centerX = x;
        if ( true ) {
            rect.y = (bar.controls.y - rect.height - margin - yOffset);

            tbr = new Array();
            var y:Float = (rect.y + margin);
            for (t in tb) {
                var r = new Rectangle(0, 0, t.width, t.height);
                r.centerX = rect.centerX;
                r.y = y;
                y += (r.h - 2);
                tbr.push( r );
            }
        }
        else {
            rect.y = (bar.y + bar.h + margin);
            tbr = new Array();
            var y:Float = (rect.y + margin);
            for (t in tb) {
                var r = new Rectangle(0, 0, t.width, t.height);
                r.centerX = rect.centerX;
                r.y = y;
                y += (r.h - 2);
                tbr.push( r );
            }
        }
    }

    /**
      * get the colors used by [this]
      */
    private function getColors():Array<Color> {
        if (colors == null) {
            var cols = new Array();
            cols.push(new Color(255, 255, 255));
            cols.push(player.theme.primary);
            colors = cols.map( player.theme.save );
            return cols;
        }
        else {
            return colors.map( player.theme.restore );
        }
    }

/* === Computed Instance Fields === */

    private var bar(get, never):SeekBar;
    private inline function get_bar() return markView.bar;

    private var player(get, never):Player;
    private inline function get_player() return bar.player;

/* === Instance Fields === */

    public var markView : SeekBarMarkView;
    public var rect : Rectangle;
    public var margin:Float = 5.0;
    public var yOffset:Float = 0.0;
    public var opacity:Float = 1.0;
    public var activated : Bool = false;

    private var tb : Array<TextBox>;
    private var ttr : Rectangle;
    private var tbr : Array<Rectangle>;
    private var colors : Null<Array<Int>> = null;
    private var border : Border;
}
