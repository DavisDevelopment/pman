package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.math.Random;
import tannus.math.*;
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
import pman.ui.ctrl.SeekBar;

import motion.Actuate;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;

class SeekBarMarkViewTooltip extends Ent {
    /* Constructor Function */
    public function new(mv : SeekBarMarkView):Void {
        super();

        markView = mv;

        tb = [new TextBox(), new TextBox(), new TextBox()];
        tbr = [new Rect(), new Rect(), new Rect()];
        border = new Border(3.0, player.theme.primary.lighten( 20 ), 3.0);
        var r = new Random();
        color = (function() {
            var base = r.choice([player.theme.secondary, player.theme.secondary.invert()]);
            var hsl = base.toHsl();
            hsl.hue += r.randfloat(-0.35, 0.35);
            return Color.fromHsl( hsl );
        }());
        tuning = [r.randbool(), r.randbool()];

        on('click', onClick);
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage: Stage):Void {
        super.init( stage );

        //_update(getColors());
        //calculateGeometry(new Rect<Float>());
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        var mr:Rect<Float> = markView.rect();

        var shouldRecalc:Bool = true;

        if ( shouldRecalc ) {
            var colors = getColors();
            _update( colors );
            calculateGeometry(cast stage.rect);
        }
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        // if [this] is flagged to cache its display
        if (cacheAsBitmap()) {
            // if there's no canvas to draw the cache onto
            if (cc == null) {
                // create one
                cc = Canvas.offscreen(w.ceil(), h.ceil());
                geomChangedSinceRedraw = true;
            }

            //if redrawing the cache is deemed necessary
            if (needsRedraw()) {
                cc.resize(ceil(w + 5), ceil(h + 5));
                _paint( cc.context );
            }

            // draw the cache 'bitmap' onto the screen
            c.drawComponent(cc, 0, 0, cc.width, cc.height, x, y, cc.width, cc.height);
            return ;
        }

        c.save();
        c.globalAlpha = opacity;
        var colors = getColors();
        
        // draw background
        c.beginPath();
        c.fillStyle = colors[1];
        c.drawRoundRect(rect, 3.0);
        c.closePath();
        c.fill();

        // draw border
        c.beginPath();
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.stroke();

        // draw textual data
        for (index in 0...tb.length) {
            var t = tb[index];
            var r = tbr[index];
            c.drawComponent(t, 0, 0, t.width, t.height, r.x, r.y, r.w, r.h);
        }

        c.restore();
    }

    /**
      * Paint [this]
      */
    public function _paint(?c: Ctx):Void {
        if (c == null) c = cc.context;
        var tmp = rect.clone();
        rect.enlarge(5.0, 5.0);
        rect.x = rect.y = 0.0;
        rect.enlarge(-5.0, -5.0);
        //cc.resize(tmp.width.ceil(), tmp.height.ceil());

        c.save();
        c.globalAlpha = opacity;
        var colors = getColors();

        // draw the background
        c.beginPath();
        c.fillStyle = colors[1];
        c.drawRoundRect(rect, 3.0);
        c.closePath();
        c.fill();

        // draw the border
        c.beginPath();
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.stroke();

        // draw the text-boxes
        for (index in 0...tb.length) {
            var t = tb[index];
            var r = tbr[index];
            c.drawComponent(t, 0, 0, t.width, t.height, 3.0, 3.0, ceil(r.w), ceil(r.h));
        }
        c.restore();

        rect = tmp;
        geomChangedSinceRedraw = false;
    }

    /**
      * update [this]
      */
    public function _update(colors: Array<Color>):Void {
        ttr = new Rect();

        // assign properties to all text-boxes
        for (t in tb) {
            t.fontSizeUnit = 'px';
            t.color = colors[0];
        }

        // update TextBox properties, one-by-one
        var t:TextBox = tb[0];
        t.text = markView.name;
        t.bold = true;
        t.fontSize = 11;
        t.color = colors[0];

        t = tb[1];
        var hk:Maybe<HotKey> = markView.hotKey();
        if (hk == null) {
            t.text = '(none)';
            t.fontSize = 11;
            t.color = colors[1].darken( 15 );
        }
        else {
            var keyName = hk.char.aschar.toLowerCase();
            if ( hk.shift ) {
                keyName = keyName.toUpperCase();
            }
            t.text = ('(' + keyName + ')');
            t.fontSize = 11;
            t.color = player.theme.secondary;
        }

        t = tb[2];
        if (t != null) {
            var time:Time = new Time( markView.mark.time );
            t.text = time.toString();
            t.fontSize = 9.5;
            t.color = colors[0];
        }

        // calculate the total content rectangle for the text
        switch ( tb.length ) {
            // without time
            case 2:
                ttr.width = (tb[0].width + tb[1].width);
                ttr.height = (tb[0].height + tb[1].height);

            // with time
            case 3:
                ttr.width = max(tb[0].width, (tb[1].width + tb[2].width + dbl( margin )));
                ttr.height = sum([tb[0].height, max(tb[1].height, tb[2].height)]);

            // urinal, poo
            default:
                throw 'invalid text-box count';
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(_r : Rect<Float>):Void {
        _update(getColors());
        var mr = markView.rect();
        w = (ttr.width + dbl( margin ));
        h = (ttr.height + margin);

        tbr = new Array();
        var yy:Float = (y + margin);

        switch ( tb.length ) {
            // without time
            case 2:
                for (t in tb) {
                    var r = new Rect(0.0, 0.0, t.width, t.height);
                    r.centerX = centerX;
                    r.y = yy;
                    yy += (r.h - 2);
                    tbr.push( r );
                }

            // with time
            case 3:
                // title
                var t:TextBox = tb[0];
                var r:Rect<Int> = new Rect(0.0, yy, t.width, t.height).floor();
                r.centerX = centerX;
                r = r.floor();
                yy += (r.h - 2);
                tbr.push(cast r);

                // determine 2nd row height
                var rh:Float = max(tb[1].height, tb[2].height);

                // hotkey
                t = tb[1];
                //yy += rh;
                r = new Rect((x + half( margin )), (yy + half(rh) - half(t.height)), t.width, t.height).floor();
                tbr.push(cast r);

                // time
                t = tb[2];
                //yy += rh;
                r = new Rect((x + w - t.width - half( margin )), (yy + half( rh ) - half( t.height )), t.width, t.height).floor();
                tbr.push(cast r);

            // invalid
            default:
                throw 'betty';
        }

        geomChangedSinceRedraw = true;
    }

    /**
      * get the colors used by [this]
      */
    private function getColors():Array<Color> {
        if (colors == null) {
            var cols = new Array();
            cols.push(new Color(255, 255, 255));
            cols.push( player.theme.primary );
            colors = cols.map( player.theme.save );
            return cols;
        }
        else {
            return colors.map( player.theme.restore );
        }
    }

    /**
      * declare that [this] MarkViewTooltip has been 'activated' (selected)
      */
    public function activate():Void {
        activated = true;
        _hide();
    }

    /**
      * hide [this]
      */
    private function _hide():Void {
        var a = Actuate.tween(this, 0.75, {
            opacity: 0.0
        });
        a.onComplete(function() {
            activated = false;
            opacity = 1.0;
        });
    }

    /**
      * handle click events
      */
    private function onClick(event : MouseEvent):Void {
        bar.controls.unlockUiVisibility();
        bar.bmnav = false;
        player.currentTime = markView.time;
        @:privateAccess player.app.keyboardCommands._nextKeyDown = [];
    }

    private static inline function dbl<T:Float>(x: T):T return (x * 2);
    private static inline function half(x: Float):Float return (x * 0.5);

    /**
      * calculate whether a redraw is necessary
      */
    private inline function needsRedraw():Bool {
        return (true && geomChangedSinceRedraw);
    }

    private inline function cacheAsBitmap():Bool {
        return false;
    }

/* === Computed Instance Fields === */

    private var bar(get, never):SeekBar;
    private inline function get_bar() return markView.bar;

    private var player(get, never):Player;
    private inline function get_player() return bar.player;

    public var progress(get, never):Percent;
    private inline function get_progress() return Percent.percent(markView.time, player.durationTime);

/* === Instance Fields === */

    public var markView : SeekBarMarkView;
    public var group: Null<SeekBarMarkViewTooltipGroup> = null;
    public var margin:Float = 6.0;
    public var yOffset:Float = 0.0;
    public var opacity:Float = 1.0;
    public var activated : Bool = false;
    public var hovered : Bool = false;
    public var color : Color;
    public var tuning : Array<Bool>;
    public var image: Null<Image> = null;

    private var tb : Array<TextBox>;
    private var ttr : Rect<Float>;
    private var tbr : Array<Rect<Float>>;
    private var colors : Null<Array<Int>> = null;
    private var border : Border;

    private var cc: Null<OffscreenCanvas> = null;
    private var geomChangedSinceRedraw:Bool = false;
}
