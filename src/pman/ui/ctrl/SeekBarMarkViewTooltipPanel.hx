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

import motion.Actuate;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:access( pman.ui.ctrl.SeekBar )
class SeekBarMarkViewTooltipPanel extends Ent {
    /* Constructor Function */
    public function new(bar : SeekBar):Void {
        super();

        this.bar = bar;
        this.tips = new Array();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        if ( bar.bmnav ) {
            for (tip in tips) {
                tip.render(stage, c);
            }
        }
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        if ( bar.bmnav ) {
            positionTips();
            var anyHovered:Bool = false;
            var mp = stage.getMousePosition();
            if (mp != null) {
                for (t in tips) {
                    if (t.hovered = t.containsPoint( mp )) {
                        anyHovered = true;
                    }
                }
            }
            if (mp != null && containsPoint( mp )) {
                if ( anyHovered ) {
                    stage.cursor = 'pointer';
                }
                else {
                    stage.cursor = 'default';
                }
            }
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        rect.cloneFrom( playerView.rect );
    }

    /**
      * calculate the positions of the tooltips
      */
    private function positionTips():Void {
        var left = new Array();
        var right = new Array();
        for (t in tips) {
            
            (t.side?right:left).push( t );
        }

        var margin:Float = 10.0;
        var pr = playerView.rect;
        var p = new Point((pr.x + margin), (pr.y + margin));
        for (t in left) {
            t.update( stage );
            t.x = p.x;
            t.y = p.y;
            p.y += (t.h + margin);
            t.calculateGeometry( rect );
        }

        p = new Point((pr.x + pr.w - margin), (pr.y + margin));
        for (t in right) {
            t.update( stage );
            t.x = (p.x - t.w);
            t.y = p.y;
            p.y += (t.h + margin);
            t.calculateGeometry( rect );
        }
    }

    /**
      * determine whether [p] is inside of [this]
      */
    override function containsPoint(p : Point):Bool {
        if ( bar.bmnav ) {
            for (tip in tips) {
                if (tip.containsPoint( p )) {
                    return true;
                }
            }
        }
        return false;
    }

    override function getChildren():Array<Entity> {
        return cast tips;
    }

    /**
      * clear [this] panel
      */
    public function clear():Void {
        tips = new Array();
    }

    /**
      * add a tooltip
      */
    public function addTooltip(t : SeekBarMarkViewTooltip):Void {
        if (!tips.has( t )) {
            tips.push( t );
            _sort();
        }
    }

    /**
      * sort [tips]
      */
    private function _sort():Void {
        tips.sort.fn([x,y] => Reflect.compare(x.markView.time, y.markView.time));
    }

/* === Computed Instance Fields === */

    public var controls(get, never):PlayerControlsView;
    private inline function get_controls() return bar.controls;

    public var playerView(get, never):PlayerView;
    private inline function get_playerView() return bar.playerView;

    public var player(get, never):Player;
    private inline function get_player() return bar.player;

/* === Instance Fields === */

    public var bar : SeekBar;
    public var tips : Array<SeekBarMarkViewTooltip>;
}
