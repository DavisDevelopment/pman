package pman.ui.tabs;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import electron.MenuTemplate;

import pman.core.*;
import pman.async.*;
import pman.display.*;
import pman.display.media.*;
import pman.media.Track;
import pman.ui.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;
using pman.async.VoidAsyncs;

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

        var _ptt:Null<String> = tb.text;
        var d = new Maybe(tab.track.ternary(_.data, null));
        var titleText:String = tab.title.ternary(_.slice(0, 15), 'New Tab');
        if (titleText.hasContent() && tb.text != titleText) {
            var recalc:Bool = (tb.text.hasContent());

            tb.text = titleText;

            if ( recalc ) {
                hasUpdated = true;
            }
        }

        if (content != null) {
            var dd = content.data;
            if (dd != null) {
                if (dd.starred && leftIcon == null) {
                    leftIcon = Icons.starIcon(16, 16, function(path) {
                        path.style.fill = player.theme.secondary.lighten( 45.0 ).toString();
                    }).toImage();
                    hasUpdated = true;
                }
                else if (!dd.starred && leftIcon != null) {
                    leftIcon = null;
                    hasUpdated = true;
                }
            }
        }

        if (mouseDown != null) {
            var mp = stage.getMousePosition();
            if (mp != null) {
                dragRect = new Rect((mp.x - mouseDown.x), y, w, h);
                //trace(dragRect.toString());
            }
        }

        // compare sizes
        if (prevRect == null) {
            //prevRect = rect.clone();
            null;
        }
        else if (prevRect.nequals( rect )) {
            trace('$prevRect !== $rect');
        }

        // update prevRect
        prevRect = rect.clone();
    }

    /**
      * render [this] Tab view
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
        inline function half(x:Float) return (x * 0.5);
        var _r = rect.clone();
        if (dragRect != null)
            rect = dragRect;

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

        var lir:Null<Rect<Float>> = null;
        var li:Null<Image> = leftIcon;
        // draw the left icon
        if (li != null) {
            lir = new Rect((ir.x + 1.33), (ir.y + half(ir.h - li.height)), li.width, li.height);
            //try {
                c.drawComponent(li, 
                    0, 0, li.width, li.height,
                    lir.x, lir.y, lir.w, lir.h
                );
            //}
        }

        // draw the title
        if (tb.text != null && tb.text != '') {
            // draw the title's text
            var tbr:Rect<Float> = new Rect((ir.x + 3.0), (ir.centerY - ((tb.height - 3.5) / 2)), tb.width, tb.height);
            if (li != null && lir != null) {
                tbr.x = (lir.w + 2.0 + tbr.x);
            }
            c.drawComponent(tb, 
                0, 0, tb.width, tb.height,
                tbr.x, tbr.y, tbr.w, tbr.h
            );
        }

        // draw the closeButton
        var ci:Image = closeIcon[closeHovered?1:0];
        var cir:Rect<Float> = new Rect((ir.x + ir.w - ci.width - 3.0), (ir.y + ((ir.h - ci.height) / 2)), ci.width, ci.height);

        // draw the hoveredness
        if ( closeHovered ) {
            var dif:Float = 2.5;
            var bge = new Ellipse(
                (cir.x + dif / 2), (cir.y + dif / 2),
                (cir.w - dif), (cir.h - dif)
            );
            c.beginPath();
            c.fillStyle = player.theme.secondary;
            //c.drawVertices(bge.getVertices());
            c.drawEllipse( bge );
            c.closePath();
            c.fill();
        }

        // draw the icon itself
        c.drawComponent(ci, 
            0, 0, ci.width, ci.height,
            cir.x, cir.y, cir.width, cir.height
        );

        rect = _r;
        c.restore();
    }

    /**
      * draw the path for [this] Tab view
      */
    private function _path(c:Ctx, r:Float, outline:Bool=false):Void {
        var lw:Float = c.lineWidth;
        var hlw:Float = (lw / 2);
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
    override function calculateGeometry(r : Rect<Float>):Void {
        inline function leftMargin() {
            return 
            if (leftIcon == null)
                0.0;
            else {
                (3.5 + leftIcon.width + 8.0);
            }
        }

        w = (leftMargin() + min(tb.width, 100) + 8.0 + closeIcon[0].width + bw);
        h = 24.0;
        y = (bar.y + (bar.h - h));
    }

    /**
      * 'click' event handler
      */
    public function onClick(event : MouseEvent):Void {
        //var ir = getInnerRect();
        //var cir:Rectangle = new Rectangle((ir.x + ir.w - ci.width - 3.0), (ir.y + ((ir.h - ci.height) / 2)), ci.width, ci.height);
        //if (cir.containsPoint( event.position )) {
        if ( closeHovered ) {
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
        var pos = event.position;
        buildMenu(function(?error, ?menu) {
            if (menu != null) {
                menu.toMenu().popup(pos.x, pos.y);
            }
        });
    }

    /**
      * close [this] tab
      */
    public inline function close():Void {
        tab.close();
    }

    /**
      * select [this] tab
      */
    public inline function select():Void {
        tab.focus();
    }

    /**
      * get the 'inner' rectangle
      */
    public function getInnerRect():Rect<Float> {
        return new Rect((x + bd), y, (w - bw), h);
    }

    /**
      * end of dragging something
      */
    public function dragEnd():Void {
        var newIndex:Int = bar.getDraggedIndex();
        trace('new index: $newIndex');
        bar.moveTabView(this, newIndex);
    }

    /**
      * build the context menu
      */
    public function buildMenu(complete : Cb<MenuTemplate>):Void {
        defer(function() {
            var menu:MenuTemplate = new MenuTemplate();
            var tasks:Array<VoidAsync> = new Array();

            tasks.push(function(done : VoidCb) {
                bar.buildMenu(function(?error, ?barMenu) {
                    if (error != null)
                        done( error );
                    else if (barMenu != null) {
                        menu = menu.concat( barMenu );
                        menu.push({type: 'separator'});
                        done();
                    }
                });
            });

            tasks.push(function(done) {
                menu.push({
                    label: 'Close tab',
                    click: function(i,w,e) {
                        close();
                    }
                });

                menu.push({
                    label: 'Close other tabs',
                    click: function(i,w,e) {
                        for (tab in bar.tabs) {
                            if (tab != this) {
                                tab.close();
                            }
                        }
                    }
                });

                menu.push({
                    label: 'Duplicate',
                    click: function(i,w,e) {
                        session.newTab(function(clonedTab) {
                            clonedTab.playlist = tab.playlist.copy();
                            clonedTab.blurredTrack = tab.track;
                        });
                    }
                });

                done();
            });

            tasks.series(function(?error) {
                complete(error, menu);
            });
        });
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return bar.player;

    public var session(get, never):PlayerSession;
    private inline function get_session() return player.session;

    public var active(get, never):Bool;
    private inline function get_active() return (tab == session.activeTab);

    public var dragging(get, never):Bool;
    private inline function get_dragging() return (mouseDown != null);

    public var content(get, never):Null<Track>;
    private inline function get_content() return tab.track;

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
    public var leftIcon: Null<Image> = null;

    public var hovered : Bool = false;
    public var closeHovered : Bool = false;
    public var hasUpdated: Bool = false;
    public var mouseDown : Null<Point<Float>> = null;
    public var dragRect : Null<Rect<Float>> = null;

    private var prevRect: Null<Rect<Float>> = null;
}
