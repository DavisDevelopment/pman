package pman.ui.tabs;

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
import pman.ui.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;

class TabView extends Ent {
    /* Constructor Function */
    public function new(bar:TabViewBar, tab:PlayerTab):Void {
        super();

        this.bar = bar;
        this.tab = tab;
        
        tb = new TextBox();
        tb.fontFamily = 'Ubuntu';
        tb.fontSize = 9.0;
        tb.fontSizeUnit = 'pt';
        tb.color = new Color(255, 255, 255);
        closeIcon = [
            Icons.closeIcon(14, 14).toImage(),
            Icons.closeIcon(14, 14, function(path:vex.core.Path) {
                path.style.fill = 'white';
            }).toImage()
        ];
    }

/* === Instance Methods === */

    /**
      * update [this] Tab view
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        var d = new Maybe(tab.track.ternary(_.data, null));
        var titleText:String = tab.title.ternary(_.slice(0, 15), '');
        if (titleText != '') {
            var starred = d.ternary(_.starred, false);
            if (starred) {
                titleText = ('*' + titleText).slice(0, 15);
            }
        }
        if (tb.text != titleText) {
            tb.text = titleText;
        }
    }

    /**
      * render [this] Tab view
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        var colors = bar.getColors();
        var ir = getInnerRect();

        c.save();

        // draw tab view background
        c.beginPath();
        c.fillStyle = colors[2];
        _path(c, 2.0);
        c.closePath();
        c.fill();

        // draw tab view outline
        c.beginPath();
        c.strokeStyle = colors[3];
        c.lineWidth = 0.8;
        c.lineCap = 'square';
        _path(c, 2.0, true);
        if ( !active )
            c.closePath();
        c.stroke();

        // draw the title
        if (tab.title != null && tab.title != '') {
            // draw the title's text
            var tbr:Rectangle = new Rectangle((ir.x + 3.0), (ir.centerY - ((tb.height - 3.5) / 2)), tb.width, tb.height);
            c.drawComponent(tb, 
                0, 0, tb.width, tb.height,
                tbr.x, tbr.y, tbr.w, tbr.h
            );
        }

        // draw the closeButton
        var ci:Image = closeIcon[closeHovered?1:0];
        var cir:Rectangle = new Rectangle((ir.x + ir.w - ci.width - 3.0), (ir.y + ((ir.h - ci.height) / 2)), ci.width, ci.height);
        // draw the hoveredness
        if ( closeHovered ) {
            var dif:Float = 2.5;
            var bge = new Ellipse(
                (cir.x + dif / 2), (cir.y + dif / 2),
                (cir.w - dif), (cir.h - dif)
            );
            c.beginPath();
            c.fillStyle = player.theme.secondary;
            c.drawVertices(bge.getVertices());
            c.closePath();
            c.fill();
        }
        c.drawComponent(ci, 
            0, 0, ci.width, ci.height,
            cir.x, cir.y, cir.width, cir.height
        );

        c.restore();
    }

    /**
      * draw the path for [this] Tab view
      */
    private function _path(c:Ctx, r:Float, outline:Bool=false):Void {
        var lw:Float = c.lineWidth, hlw:Float = (lw / 2);
        if ( outline ) {
            x += hlw;
            y += hlw;
            w -= lw;
            h -= lw;
        }

        // bottom-left
        c.moveTo(x, y + h);
        // bottom-left to top-left
        c.lineTo(x + bd, y + r);
        c.quadraticCurveTo(x + bd, y + r, x + bd + r, y);
        // top-left to top-right
        c.lineTo(x + w - bd - r, y);
		c.quadraticCurveTo(x + w - bd, y, x + w - bd, y + r);
		// top-right to bottom-right
		c.lineTo(x + w, y + h);
    }

    /**
      * calculate [this] view's content rectangle
      */
    override function calculateGeometry(r : Rectangle):Void {
        rect.w = (min(tb.width, 100) + 8.0 + closeIcon[0].width + bw);
        rect.h = 24.0;
        rect.y = (bar.y + (bar.h - rect.h));
    }

    /**
      * 'click' event handler
      */
    public function onClick(event : MouseEvent):Void {
        var cir:Rectangle = new Rectangle((x + w - ci.width - 3.0), (y + ((h - ci.height) / 2)), ci.width, ci.height);
        if (cir.containsPoint( event.position )) {
            close();
        }
        else {
            select();
        }
    }

    /**
      * 'rightclick' event handler
      */
    public function onRightClick(event : MouseEvent):Void {
        event.cancel();
    }

    /**
      * close [this] tab
      */
    public inline function close():Void {
        session.deleteTab(session.tabs.indexOf( tab ));
    }

    /**
      * select [this] tab
      */
    public inline function select():Void {
        session.setTab(session.tabs.indexOf( tab ));
    }

    /**
      * get the 'inner' rectangle
      */
    public function getInnerRect():Rectangle {
        return new Rectangle((x + bd), y, (w - bw), h);
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return bar.player;

    public var session(get, never):PlayerSession;
    private inline function get_session() return player.session;

    public var active(get, never):Bool;
    private inline function get_active() return (tab == session.activeTab);

    public var ci(get, never):Null<Image>;
    private inline function get_ci() return closeIcon[closeHovered ? 1 : 0];

    public var bd(get, never):Float;
    private inline function get_bd() return bw / 2;

/* === Instance Fields === */

    public var bw : Float = 14;
    public var bar : TabViewBar;
    public var tab : PlayerTab;

    public var tb : TextBox;
    public var closeIcon : Array<Image>;

    public var hovered : Bool = false;
    public var closeHovered : Bool = false;
}
