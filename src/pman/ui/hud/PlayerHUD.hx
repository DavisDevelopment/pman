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

class PlayerHUD extends Ent {
    /* Constructor Function */
    public function new(p : PlayerView):Void {
        super();

        playerView = p;
        items = new Array();
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
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        rect = playerView.rect.clone();

        super.calculateGeometry( r );
    }

/* === Instance Fields === */

    public var playerView : PlayerView;
    public var items : Array<PlayerHUDItem>;
}
