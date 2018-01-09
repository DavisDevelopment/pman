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
import pman.ui.hud.*;
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
        this.groups = new Dict();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        super.init( stage );

        bar.on('bmnav:abort', untyped function() {
            if (hasOpenTooltipGroup()) {
                closeTooltipGroup();
            }
        });
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        if ( bar.bmnav ) {
            //for (tip in tips) {
                //tip.render(stage, c);
            //}
            for (group in groups) {
                group.render(stage, c);
            }
        }
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        if ( bar.bmnav ) {
            //tips.sort(function(x, y) {
                //return Reflect.compare(x.markView.mark.time, y.markView.mark.time);
            //});
            _sort();
            //positionTips();
            positionGroups();

            var anyHovered:Bool = false;
            var mp = stage.getMousePosition();
            if (mp != null) {
                for (g in groups) {
                    if (g.hovered = g.containsPoint( mp )) {
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

        if (fps == null) {
            fps = stage.get('..FPSDisplay').selected[0];
            if (fps != null) {
                calculateGeometry( rect );
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
      * calculate the positions of the tooltip groups
      */
    private function positionGroups():Void {
        var pr = playerView.rect;
        var margin:Float = 10.0, p = new Point((pr.x + margin), (pr.y + margin));
        for (g in groups) {
            g.update( stage );
            g.x = p.x;
            g.y = p.y;
            p.x += (g.w + margin);
            g.calculateGeometry( rect );
        }
    }

    /**
      * calculate the positions of the tooltips
      */
    /*
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
        if (fps != null) {
            p.y = (fps.y + fps.h + (margin * 2));
        }
        for (t in right) {
            t.update( stage );
            t.x = (p.x - t.w);
            t.y = p.y;
            p.y += (t.h + margin);
            t.calculateGeometry( rect );
        }
    }
    */

    /**
      * determine whether [p] is inside of [this]
      */
    override function containsPoint(p : Point):Bool {
        if ( bar.bmnav ) {
            for (g in groups) {
                if (g.containsPoint( p )) {
                    return true;
                }
            }
            //for (tip in tips) {
                //if (tip.containsPoint( p )) {
                    //return true;
                //}
            //}
        }
        return false;
    }

    override function getChildren():Array<Entity> {
        return cast groups;
    }

    /**
      * clear [this] panel
      */
    public function clear():Void {
        tips = new Array();
        groups = new Dict();
    }

    /**
      * add a tooltip-group
      */
    public function addTooltipGroup(?firstWord:String, ?group:SeekBarMarkViewTooltipGroup):SeekBarMarkViewTooltipGroup {
        if (firstWord != null && group != null) {
            throw 'Error: Either firstWord or group must be provided. Not both';
        }
        else if (firstWord != null) {
            return addTooltipGroup(null, new SeekBarMarkViewTooltipGroup(this, firstWord));
        }
        else if (group != null) {
            groups[group.word] = group;
            group.parent = cast this;
            recalculateGroupIndices();
            dispatch('group:created', group);
            return group;
        }
        else {
            throw 'Error: Either firstWord or group must be provided';
        }
    }

    /**
      * ensure that a tooltip group for [firstWord] exists
      */
    public inline function ensureTooltipGroup(firstWord: String):SeekBarMarkViewTooltipGroup {
        if (!groups.exists( firstWord )) {
            return addTooltipGroup( firstWord );
        }
        else {
            return groups.get( firstWord );
        }
    }

    /**
      * add a tooltip
      */
    public function addTooltip(t : SeekBarMarkViewTooltip):Void {
        // the Mark for which [t] exists
        var m:Mark = t.markView.mark.toNonNullable();

        // the first word of the Mark's name
        var fw:String = m.firstWord();

        // append [t] to the tooltip-group corresponding with [fw]
        ensureTooltipGroup( fw ).addTooltip( t );
    }

    /**
      * handle bookmark navigation keydown events
      */
    @:access( pman.ui.ctrl.SeekBar )
    public function handle_bmnav(event: KeyboardEvent):Void {
        var status:Bool = false;
        bar.bmnav = false;
        if (!hasOpenTooltipGroup()) {
            for (g in groups) {
                var hotKey = g.getHotKey().toNonNullable();
                if (hotKey != null && SeekBar.checkEventWithHotKey(hotKey, event)) {
                    openTooltipGroup( g );
                    status = true;
                    break;
                }
            }
            trace(status ? 'a group was opened' : 'no group opened');
        }
        else {
            currentlyOpenGroup.handle_bmnav( event );
            closeTooltipGroup();
            //currentlyOpenGroup = null;
            //bar.bmnav = false;
        }
    }

    /**
      * open a tooltip-group
      */
    public inline function openTooltipGroup(group: SeekBarMarkViewTooltipGroup):Void {
        if (hasOpenTooltipGroup()) {
            closeTooltipGroup();
        }
        
        if (group.members.length == 1) {
            var tip = group.members[0];
            var m = tip.markView.mark;
            if (m != null) {
                player.currentTime = m.time;
            }

            return defer(defer.bind(function() {
                bar.abortBookmarkNavigation();
            }));
        }

        currentlyOpenGroup = group;
        group.open();
        bar.bmnav = true;
    }

    /**
      * closes the currently open tooltip-group
      */
    public inline function closeTooltipGroup():Void {
        minimizeTooltipGroup();
        bar.bmnav = false;
    }

    public inline function minimizeTooltipGroup():Void {
        if (hasOpenTooltipGroup()) {
            getOpenTooltipGroup().close();
            currentlyOpenGroup = null;
        }
    }

    /**
      * check whether there are any marks attached to the Track
      */
    public function hasAnyMarks():Bool {
        for (group in groups) {
            if (!group.members.empty()) {
                return true;
            }
        }
        return false;
    }

    /**
      * check that there is currently an open tooltip-group
      */
    public inline function hasOpenTooltipGroup():Bool {
        return (currentlyOpenGroup != null);
    }

    public inline function getOpenTooltipGroup():Maybe<SeekBarMarkViewTooltipGroup> return currentlyOpenGroup;

    /**
      * calculate tooltip-group indices
      */
    private function recalculateGroupIndices():Void {
        var i:Int = 0;
        for (g in groups)
            g.index = i++;
    }

    /**
      * sort [tips]
      */
    private function _sort():Void {
        var sorter = ((x:SeekBarMarkViewTooltip, y:SeekBarMarkViewTooltip) -> Reflect.compare(x.markView.time, y.markView.time));
        for (g in groups) {
            g.members.sort( sorter );
        }
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
    public var groups : Dict<String, SeekBarMarkViewTooltipGroup>;

    public var fps : Null<FPSDisplay> = null;
    
    // the tooltip-group that is currently open
    private var currentlyOpenGroup: Null<SeekBarMarkViewTooltipGroup> = null;
}
