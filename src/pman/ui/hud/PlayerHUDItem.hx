package pman.ui.hud;

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

class PlayerHUDItem extends Ent {
    /* Constructor Function */
    public function new(p : PlayerHUD):Void {
        super();

        hud = p;
        margin = 20;
        duration = 4000;
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        super.init( stage );
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        enabled = (!playerView.controls.uiEnabled && getEnabled());
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        super.calculateGeometry( r );
    }

    /**
      * determine whether [this] is enabled
      */
    private function getEnabled():Bool {
        return false;
    }

/* === Computed Instance Fields === */

    public var playerView(get, never):PlayerView;
    private inline function get_playerView() return hud.playerView;

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

/* === Instance Fields === */

    public var hud : PlayerHUD;
    public var margin : Float;
    public var duration : Float;
    public var enabled : Bool = false;
    
    //private var showTime : Null<Float> = null;
}
