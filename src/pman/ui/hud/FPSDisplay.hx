package pman.ui.hud;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.Percent;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Border;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class FPSDisplay extends TextualHUDItem {
    /* Constructor Function */
    public function new(hud : PlayerHUD):Void {
        super( hud );

        frames = new Pair(0, 0);
        lt = null;
        _fpsData = new Array();
        tb.color = new Color(34, 245, 51);
        tb.fontSize = 12;
    }

/* === Instance Methods === */

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        if (lt == null) {
            lt = now();
        }
        else {
            if ((now() - lt) >= 1000) {
                frames.right = frames.left;
                frames.left = 0;
                lt = now();
                addFps( frames.right );
            }
            else {
                frames.left++;
            }
        }

        tb.text = 'FPS: ${frames.right}';
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        c.drawComponent(tb, 0, 0, tb.width, tb.height, x, y, tb.width, tb.height);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        r = player.view.rect;

        x = (r.x + r.w - tb.width - 10);
        y = (r.y + 10);
        w = tb.width;
        h = (tb.height / 4);

        var tabs = player.view.tabBar;
        if (tabs != null) {
            //y += (tabs.y + tabs.h);
        }
    }

    /**
      * add an integer to [this]'s dataset
      */
    private function addFps(n: Int):Void {
        _fpsData.push( n );

        if (_fpsData.length > 100) {
            _fpsData = _fpsData.slice(-100);
        }
    }

/* === Instance Fields === */

    private var frames : Pair<Int, Int>;
    private var lt : Null<Float>;
    private var _fpsData: Array<Int>;
}
