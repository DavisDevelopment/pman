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

class TabViewBar extends Ent {
    /* Constructor Function */
    public function new(playerView : PlayerView):Void {
        super();

        this.playerView = playerView;
        tabs = new Array();

        on('click', onClick);
    }

/* === Instance Methods === */

    /**
      * add a Tab to [this]
      */
    public function addTabView(tab : TabView):TabView {
        if (!tabs.has( tab )) {
            tabs.push( tab );
        }
        return tab;
    }

    /**
      * remove a Tab from [this]
      */
    public function removeTabView(tab : TabView):Bool {
        tab.delete();
        return tabs.remove( tab );
    }

    /**
      * add a Tab to [this] widget
      */
    public function addTab(tab : PlayerTab):TabView {
        var view : TabView = getViewFor( tab );
        if (view == null) {
            view = new TabView(this, tab);
        }
        return addTabView( view );
    }

    /**
      * remove a Tab from [this] widget
      */
    public function removeTab(tab : PlayerTab):Bool {
        var view = getViewFor( tab );
        if (view == null)
            return false;
        else return removeTabView( view );
    }

    /**
      * get the view for [tab]
      */
    public function getViewFor(tab : PlayerTab):Null<TabView> {
        return tabs.filter.fn(_.tab == tab)[0];
    }

    /**
      * initialize [this] widget
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * update [this] Widget
      */
    override function update(stage : Stage):Void {
        if ( !display )
            return ;

        super.update( stage );

        if (!upToDate()) {
            refresh();
        }

        var mp = stage.getMousePosition();
        hovered = (mp != null && containsPoint( mp ));

        for (t in tabs) {
            t.hovered = false;
            t.closeHovered = false;
            t.update( stage );
        }

        if ( hovered ) {
            var cursor:String = 'default';
            var ht:Null<TabView> = null;
            for (t in tabs) {
                if (t.containsPoint( mp )) {
                    ht = t;
                    break;
                }
            }
            if (ht != null) {
                cursor = 'pointer';
                ht.hovered = true;
                if (mp.containedBy((ht.x + ht.w - ht.ci.width - 3.0), (ht.y + ((ht.h - ht.ci.height) / 2)), ht.ci.width, ht.ci.height)) {
                    ht.closeHovered = true;
                }
            }
            stage.cursor = cursor;
        }
    }

    /**
      * render [this] widget
      */
    override function render(stage:Stage, c:Ctx):Void {
        if ( !display )
            return ;

        super.render(stage, c);

        var colors = getColors();

        c.save();
        c.beginPath();
        c.drawRect( rect );
        c.fillStyle = colors[0];
        c.closePath();
        c.fill();
        c.restore();

        for (t in tabs) {
            t.render(stage, c);
        }
    }

    /**
      * calculate [this]'s content rect
      */
    override function calculateGeometry(r : Rectangle):Void {
        x = 0;
        y = 0;
        w = playerView.w;
        h = 30;

        var margin:Float = 3.8;
        var tx:Float = 0.0;

        for (t in tabs) {
            tx += margin;
            t.x = tx;
            tx += (t.w + margin);

            t.calculateGeometry( rect );
        }
    }

    /**
      * get the color scheme
      */
    public function getColors():Array<Color> {
        if (colors == null) {
            var bg = player.theme.primary.lighten( 60 );
            var bga = player.theme.primary;
            var fg = bg.lighten( 75 );
            var fga = bg.lighten( 18 );
            var _colors = [bg, bga, fg, fga];
            colors = _colors.map( player.theme.save );
            return _colors;
        }
        else {
            return colors.map( player.theme.restore );
        }
    }

    /**
      * check whether the tab views are synced with the tabs
      */
    public function upToDate():Bool {
        if (tabs.length != session.tabs.length) {
            return false;
        }
        else {
            for (index in 0...tabs.length) {
                if (tabs[index].tab != session.tabs[index]) {
                    return false;
                }
            }
            return true;
        }
    }

    /**
      * rebuild the [tabs] field
      */
    public function refresh():Void {
        for (tab in tabs) {
            removeTabView( tab );
        }
        for (tab in session.tabs) {
            addTab( tab );
        }
    }

    /**
      * 'click' event handler
      */
    public function onClick(event : MouseEvent):Void {
        var p:Point = event.position;
        for (t in tabs) {
            if (t.containsPoint( p )) {
                t.onClick( event );
                return ;
            }
        }
    }

    /**
      * check whether [p] is inside of [this]'s content rect
      */
    override function containsPoint(p : Point):Bool {
        return display ? super.containsPoint( p ) : false;
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

    public var session(get, never):PlayerSession;
    private inline function get_session() return player.session;

    public var display(get, never):Bool;
    private inline function get_display():Bool return (session.tabs.length > 1);

/* === Instance Fields === */

    public var playerView : PlayerView;
    public var tabs : Array<TabView>;
    public var hovered : Bool = false;

    private var colors : Null<Array<Int>> = null;
}
