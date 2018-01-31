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

class StatusBarItem extends Ent {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * [this] has been attached to the status bar
      */
    public function attached(sb : PlayerStatusBar):Void {
        statusBar = sb;
        attachedOn = now;
    }

    /**
      * initialize [this] StatusBar item
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * update [this] StatusBar item
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        if (duration > -1) {
            if ((now - attachedOn) >= duration) {
                delete();
            }
        }
    }

    /**
      * render [this] StatusBar item
      */
    override function render(stage:Stage, c:Ctx):Void {
        null;
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        rect.pull( r );
    }

    /**
      * delete [this]
      */
    override function delete():Void {
        super.delete();
        statusBar.item = null;
        if (prevItem != null) {
            statusBar.attach( prevItem );
        }
    }

/* === Computed Instance Fields === */

    public var playerView(get, never):PlayerView;
    private inline function get_playerView() return statusBar.playerView;

    public var player(get, never):Player;
    private inline function get_player() return statusBar.player;

/* === Instance Fields === */

    public var duration : Float;
    public var statusBar : PlayerStatusBar;

    @:allow( pman.ui.statusbar.PlayerStatusBar )
    private var prevItem : Null<StatusBarItem> = null;
    private var attachedOn : Null<Float> = null;
}
