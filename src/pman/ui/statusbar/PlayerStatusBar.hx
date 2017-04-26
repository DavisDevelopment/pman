package pman.ui.statusbar;

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

        if (item != null) {
            item.update( stage );
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
    override function calculateGeometry(r : Rectangle):Void {
        r = playerView.rect;
        
        w = r.w;
        h = 16;
        y = (playerView.controls.y + playerView.controls.h);
        x = playerView.x;

        if (item != null) {
            item.calculateGeometry( rect );
        }
    }

    /**
      * attach the given StatusBarItem to [this]
      */
    public function attach(i : StatusBarItem):Void {
        var old = item;
        item = i;
        item.attached( this );
        item.prevItem = old;
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

/* === Instance Fields === */

    public var playerView : PlayerView;
    public var item : Null<StatusBarItem> = null;
}
