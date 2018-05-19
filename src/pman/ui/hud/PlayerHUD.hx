package pman.ui.hud;

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
import pman.ui.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
//import electron.Tools.*;
import edis.Globals.*;
import pman.Globals.*;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  the Player's "heads-up display" for when the controls are hidden
 **/
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

        defer(function() {
            addItem(new ProgressItem( this ));
            addItem(new VolumeItem( this ));
            addItem(new TitleItem( this ));
            addItem(new ToggleableItem( this ));

            #if debug

            addItem(new FPSDisplay( this ));
            //addItem(new MemoryUsageDisplay( this ));

            #end
        });
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        calculateGeometry(stage.rect.float());
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        var pvr:Rect<Float> = playerView.rect;
        var pvmr:Rect<Float> = playerView.mediaRect;
        if (pvmr == null) {
            pvmr = pvr;
        }

        if (pvr != null && pvmr != null) {
            rect.set(
                pvr.x, pvmr.y,
                pvr.w, pvmr.h
            );
        }

        super.calculateGeometry( r );
    }

    /**
      * check if [p] is inside of [this]
      */
    override function containsPoint(p : Point<Float>):Bool {
        return false;
    }

    /**
      * add an item to [this]
      */
    public inline function addItem(item : PlayerHUDItem):PlayerHUDItem {
        items.push( item );
        addChild( item );
        return item;
    }

/* === Instance Fields === */

    public var playerView : PlayerView;
    public var items : Array<PlayerHUDItem>;
}
