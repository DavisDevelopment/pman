package pman.ui.tabs;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;
import js.html.CanvasPattern;

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

        //on('click', onClick);
        on('contextmenu', onRightClick);
        on('mousedown', onMouseDown);
        on('mouseup', onMouseUp);
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

        var _ad = anyDragging;
        anyDragging = false;

        for (t in tabs) {
            t.hovered = false;
            t.closeHovered = false;
            t.update( stage );
            if ( t.dragging ) {
                anyDragging = true;
            }
        }

        switch ([_ad, anyDragging]) {
            case [false, true]:
                //TODO

            case [true, false]:
                //TODO

            default:
                null;
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
                var htir = ht.getInnerRect();
                cursor = 'pointer';
                ht.hovered = true;
                if (mp.containedBy((htir.x + htir.w - ht.ci.width - 3.0), (htir.y + ((htir.h - ht.ci.height) / 2)), ht.ci.width, ht.ci.height)) {
                    ht.closeHovered = true;
                }
            }
            stage.cursor = cursor;
        }
        else {
            if ( anyDragging ) {
                getDraggingTabView().attempt({
                    _.mouseDown = null;
                    _.dragRect = null;
                    lastMouseDown = null;
                });
            }
        }

        if ( anyDragging ) {
            calculateGeometry( rect );
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

        // get the pattern
        if (pattern == null) {
            pattern = buildPattern(c, colors, 4, 4);
        }

        // draw the background
        c.fillStyle = colors[0];
        c.fillRect(x, y, w, h);
        if (pattern != null) {
            c.fillStyle = pattern;
            c.fillRect(x, y, w, h);
        }

        // render then tabs
        tabs.reverse();
        var priority:Array<Null<TabView>> = [null, null];
        for (t in tabs) {
            if (!t.active && !t.dragging) {
                t.render(stage, c);
            }
            else {
                if ( t.active ) {
                    priority[0] = t;
                }
                else if ( t.dragging ) {
                    priority[1] = t;
                }
            }
        }
        tabs.reverse();
        for (t in priority) if (t != null)
            t.render(stage, c);
    }

    /**
      * build the pattern
      */
    private function buildPattern(c:Ctx, colors:Array<Color>, w:Int, h:Int):CanvasPattern {
        var can = Canvas.create(w, h);
        var cc = can.context;
        cc.strokeStyle = colors[1];
        cc.moveTo((can.width / 2), 0);
        cc.lineTo((can.width / 2), can.height);
        cc.moveTo(0, (can.height / 2));
        cc.lineTo(can.width, (can.height / 2));
        cc.stroke();
        return c.createPattern(can, 'repeat');
    }

    /**
      * calculate [this]'s content rect
      */
    override function calculateGeometry(r : Rectangle):Void {
        x = 0;
        y = 0;
        w = playerView.w;
        h = 30;

        var margin:Float = 4.2;
        var tx:Float = 0.0;
        var cdt:Null<TabView> = null;
        if ( anyDragging ) {
            cdt = getDraggingTabView();
        }
        var oldTabs:Array<TabView> = tabs.copy();
        if (cdt != null) {
            var cdi = getDraggedIndex();
            tabs.remove( cdt );
            tabs.insert(cdi, cdt);
        }

        for (i in 0...tabs.length) {
            var t:TabView = tabs[i];
            tx += margin;
            t.x = tx;
            tx += (t.w - t.bw + margin);

            t.calculateGeometry( rect );
        }
    
        tabs = oldTabs;
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
        tabs = new Array();
        for (tab in session.tabs) {
            addTab( tab );
        }
        defer(function() {
            calculateGeometry( rect );
        });
    }

    /**
      * get a TabView by a Point
      */
    public function getTabViewByPoint(p : Point):Maybe<TabView> {
        for (t in tabs) {
            if (t.containsPoint( p )) {
                return t;
            }
        }
        return null;
    }

    /**
      * 'click' event handler
      */
    public function onClick(event : MouseEvent):Void {
        getTabViewByPoint( event.position ).attempt(_.onClick( event ));
    }

    /**
      * 'rightclick' event handler
      */
    public function onRightClick(event : MouseEvent):Void {
        getTabViewByPoint( event.position ).attempt(_.onRightClick( event ));
    }

    /**
      * handle 'mousedown' events
      */
    public function onMouseDown(event : MouseEvent):Void {
        var tab = getTabViewByPoint( event.position );
        if (tab != null) {
            lastMouseDown = event;
            var p = event.position;
            tab.mouseDown = new Point((p.x - tab.rect.x), (p.y - tab.rect.y));
            tab.dragRect = tab.rect.clone();
        }
    }

    /**
      * handle 'mouseup' events
      */
    public function onMouseUp(event : MouseEvent):Void {
        if (lastMouseDown != null && (event.position.distanceFrom( lastMouseDown.position ) < 33)) {
            onClick( event );
            getTabViewByPoint( event.position ).attempt({
                _.mouseDown = null;
                _.dragRect = null;
            });
        }

        for (t in tabs) {
            if (t.mouseDown != null || t.dragRect != null) {
                t.dragEnd();
                t.mouseDown = null;
                t.dragRect = null;
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

    /**
      * find the first tabview for which [f] returned true
      */
    public function findTabView(f : TabView->Bool):Maybe<TabView> {
        for (t in tabs) {
            if (f( t ))
                return t;
        }
        return null;
    }

    /**
      * get the TabView currently being dragged
      */
    public function getDraggingTabView():Maybe<TabView> {
        return findTabView.fn( _.dragging );
    }

    /**
      * get the 'dragged' index of the dragging tab
      */
    public function getDraggedIndex():Int {
        var dt = getDraggingTabView();
        if (dt == null)
            return -1;
        var di:Int = 0;
        inline function dx():Float return dt.dragRect.x;
        for (index in 0...tabs.length) {
            var t:TabView = tabs[index];
            if (dx() > t.rect.centerX) {
                di++;
            }
        }
        return di;
    }

    /**
      * move the given TabView to a new index
      */
    public function moveTabView(tab:TabView, newIndex:Int):Void {
        //var ntl = tabs.copy();
        //ntl.remove( tab );
        //ntl.insert(newIndex, tab);
        //tabs = ntl;
        //calculateGeometry( rect );
        session.moveTab(tab.tab, newIndex);
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
    public var pattern : CanvasPattern;
    public var anyDragging : Bool = false;

    private var colors : Null<Array<Int>> = null;
    private var lastMouseDown : Null<MouseEvent> = null;
}
