package pman.ui.statusbar;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

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

class PlayerStatusBar extends Ent {
    /* Constructor Function */
    public function new(pv : PlayerView):Void {
        super();

        this.playerView = pv;
        this.priority = 2;
    }

/* === Instance Methods === */

    /**
      * initialize [this] StatusBar
      */
    override function init(stage : Stage):Void {
        super.init( stage );

        attach(new DefaultStatusBarItem());
    }

    /**
      * update [this] StatusBar
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        // variable that denotes whether layout will be recalculated
        var willRecalc:Bool = true;

        // update the 'item'
        if (item != null) {
            item.update( stage );
        }

        //TODO determine whether [calculateGeometry] should be invoked

        // if so, invoke it now
        if ( willRecalc ) {
            calculateGeometry( playerView.rect );
        }
    }

    /**
      * render [this] StatusBar
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        c.save();

        c.beginPath();
        c.fillStyle = player.theme.primary.lighten( 55 );
        c.drawRect( rect );
        c.closePath();
        c.fill();

        if (item != null) {
            item.render(stage, c);
        }
        
        c.restore();
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        r = playerView.rect;
        
        w = r.w;
        h = 16.0;
        y = (playerView.controls.y + playerView.controls.h);
        x = r.x;

        if (item != null) {
            item.calculateGeometry( rect );
            
            h = max(h, item.ch);
        }
    }

    /**
      * attach the given StatusBarItem to [this]
      */
    public function attach(i : StatusBarItem):Void {
        var old:Null<StatusBarItem> = item;
        if (old != null) {
            detach( old );
        }

        item = i;
        item.attached( this );
        item.prevItem = old;
    }

    /**
      * detach the given StatusBarItem (or the currently attached one, if not provided) from [this]
      */
    public function detach(?i: StatusBarItem):Void {
        if (i == null)
            i = this.item;
        if (i != null) {
            i.detached( this );
        }
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

/* === Instance Fields === */

    public var playerView : PlayerView;
    public var item : Null<StatusBarItem> = null;
}
