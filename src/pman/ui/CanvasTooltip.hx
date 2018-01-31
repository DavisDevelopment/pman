package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.css.Value;
import tannus.css.vals.Lexer as CSSValueLexer;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.*;

import pman.core.*;

import tannus.math.TMath.*;
import electron.Tools.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.css.vals.ValueTools;

class CanvasTooltip extends Ent {
    public function new():Void {
        super();

        t = new TextBox();
        t.fontFamily = 'Ubuntu';
        t.fontSizeUnit = 'px';
        t.fontSize = 14;
        t.color = new Color(255, 255, 255);
        tr = new Rect();
        //tt = new Triangle();
        tt = {
            x: 0.0,
            w: 12.0,
            h: 12.0,
            t: new Triangle()
        };

        backgroundColor = '#333333';
        border = new Border(4, theme.primary.lighten( 22 ), 3);
        padding = new Padding();
        padding.horizontal = 6.0;
        bounds = new Rect();
        position = {
            from: new Rect(),
            spacing: 0.0,
            direction: Top
        };
    }

/* === Instance Methods === */

    /**
      * render [this] tooltip
      */
    override function render(stage:Stage, c:Ctx):Void {
        c.save();
        c.shadowBlur = 8.0;
        c.shadowColor = backgroundColor;
        render_box(stage, c);
        render_content(stage, c);
        c.restore();
    }

    /**
      *
      */
    private function render_box(stage:Stage, c:Ctx):Void {
        c.beginPath();

        // configure path properties
        c.fillStyle = backgroundColor;
        c.strokeStyle = border.color;
        c.lineWidth = border.width;

        switch ( position.direction ) {
            case Top:
                // -- build path
                // top-left to top-right
                var r = border.radius;
                c.moveTo(x + r, y);
                c.lineTo(x + w - r, y);
                c.quadraticCurveTo(x + w, y, x + w, y + r);

                // top-left to bottom-right
                c.lineTo(x + w, y + h - r);
                c.quadraticCurveTo(x + w, y + h, x + w - r, y + h);

                // bottom-right to right side of tail
                c.lineToPoint( tt.t.three );

                // right side of tail to tip of tail
                c.lineToPoint( tt.t.two );

                // tip of tail to left side of tail
                c.lineToPoint( tt.t.one );

                // left side of tail to bottom-left
                c.lineTo(x + r, y + h);
                c.quadraticCurveTo(x, y + h, x, y + h - r);

                // bottom-left to top-left
                c.lineTo(x, y + r);
                c.quadraticCurveTo(x, y, x + r, y);

            default:
                c.drawRect( rect );
        }

        // finalize and render path
        c.closePath();
        c.fill();
        c.stroke();
    }

    private function render_content(stage:Stage, c:Ctx):Void {
        c.drawComponent(
            t, 0, 0, t.width, t.height,
            tr.x, tr.y, tr.width, tr.height
        );
    }

    override function update(stage : Stage):Void {
        calculateGeometry(cast stage.rect);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        inline function dbl(x:Float) return (x*2);
        inline function half(x:Float) return (x / 2);

        var pf:Rect<Float> = position.from;

        switch ( position.direction ) {
            case Top:
                // compute content rectangle
                w = (t.width + dbl(border.width) + padding.left + padding.right);
                h = (t.height + dbl(border.width) + padding.top + padding.bottom);
                centerX = pf.centerX;
                y = (pf.y - h - position.spacing);

                // compute text box bounding rectangle
                tr.width = t.width;
                tr.height = t.height;
                tr.centerX = centerX;
                tr.centerY = centerY;

                // compute the tail triangle points
                var ttc = new Point((centerX + tt.x), (y + h)); // tail top center
                tt.t.one.x = (ttc.x - half( tt.w ));
                tt.t.one.y = (y + h);
                tt.t.two.x = ttc.x;
                tt.t.two.y = (ttc.y + tt.h);
                tt.t.three.x = (ttc.x + half( tt.w ));
                tt.t.three.y = (y + h);

            case Bottom:
                // compute content rectangle
                w = (t.width + dbl(border.width) + padding.left + padding.right);
                h = (t.height + dbl(border.width) + padding.top + padding.bottom);
                centerX = pf.centerX;
                y = (pf.y + pf.h + h + position.spacing);

                // compute text box bounding rectangle
                tr.width = t.width;
                tr.height = t.height;
                tr.centerX = centerX;
                tr.centerY = centerY;

                // compute the tail triangle points
                var ttc = new Point((centerX + tt.x), y); // tail top center
                tt.t.one.x = (ttc.x - half( tt.w ));
                tt.t.one.y = y;
                tt.t.two.x = ttc.x;
                tt.t.two.y = ttc.y + tt.h;
                tt.t.three.x = (ttc.x + half( tt.w ));
                tt.t.three.y = y;

            case Right:
                // compute content rectangle
                w = (t.width + dbl(border.width) + padding.left + padding.right);
                h = (t.height + dbl(border.width) + padding.top + padding.bottom);
                x = ((pf.x + pf.w) + position.spacing);
                centerY = pf.centerY;

                // compute text bounding rectangle
                tr.width = t.width;
                tr.height = t.height;
                tr.centerX = centerX;
                tr.centerY = centerY;

                // compute the tail triangle points
                var ttc = new Point(x, centerY);
                var i = tt.t;
                i.one.x = ttc.x;
                i.one.y = (ttc.y - half( tt.w ));
                i.two.x = (ttc.x - tt.h);
                i.two.y = ttc.y;
                i.three.x = ttc.x;
                i.three.y = (ttc.y + half( tt.w ));

            case Left:
                //TODO
        }
    }

    /**
      * compute whether [this] is entirely inside the viewport
      */
    public function isInsideViewport():Bool {
        return !(
            (x < bounds.x || (x + w) > (bounds.x + bounds.w)) ||
            (y < bounds.y || (y + h) > (bounds.y + bounds.h))
        );
    }

/* === Computed Instance Fields === */

    public var textColor(get, set):Color;
    private inline function get_textColor() return t.color;
    private inline function set_textColor(v) return (t.color = v);

    public var text(get, set):String;
    private inline function get_text() return t.text;
    private inline function set_text(v) return (t.text = v);

    public var font(get, set):String;
    private inline function get_font():String return ((''+t.fontSize+t.fontSizeUnit) + ' "${t.fontFamily}"');
    private function set_font(s : String):String {
        inline function invalid()
            throw new js.Error('Invalid value supplied to pman.ui.CanvasTooltip.set_font');
        try {
            var sv = CSSValueLexer.parseString( s );
            if (sv.length != 2)
                invalid();
            switch ( sv ) {
                // [font size], [font family]
                case [VNumber(num, unit), VIdent(fam)|VString(fam)]:
                    t.fontSizeUnit = unit;
                    t.fontSize = num;
                    t.fontFamily = fam;

                // [font family], [font size]
                case [VIdent(fam)|VString(fam), VNumber(num, unit)]:
                    t.fontSizeUnit = unit;
                    t.fontSize = num;
                    t.fontFamily = fam;

                // any other input
                default:
                    invalid();
            }
        }
        catch (error : Dynamic) {
            throw error;
        }
        return font;
    }

/* === Instance Fields === */

    public var backgroundColor : Color;
    public var border : Border;
    public var padding : Padding;
    public var position : TooltipPosition;
    public var bounds : Rect<Float>;

    private var t : TextBox;
    private var tr : Rect<Float>;
    private var tt : {x:Float, w:Float,h:Float,t:Triangle<Float>};
}

typedef TooltipPosition = {
    from: Rect<Float>,
    spacing: Float,
    direction: TooltipPositionDirection
};

enum TooltipPositionDirection {
    Top;
    Left;
    Bottom;
    Right;
}
