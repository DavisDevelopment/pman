package pman.ui.hud;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
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
import pman.time.Timer;

import edis.libs.electron.App;

import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.Tools;

class MemoryUsageDisplay extends TextualHUDItem {
    public function new(hud:PlayerHUD) {
        super( hud );

        tb.color = prev.tb.color;
        tb.multiline = true;

        //this.prev = prev;
        pid = (untyped __js__('process.pid'));
        metrics = null;

        refresh();
    }

    private function refresh():Void {
        if (memTotal == null) {
            memTotal = tannus.node.Os.totalmem();
        }

        var all = App.getAppMetrics();
        metrics = all.firstMatch.fn(_.pid == pid);

        var jsHeap:Int = (metrics.memory.privateBytes * 1000);
        var heapTxt:String = ('heap: ' + jsHeap.formatSize( false ));

        tb.text = heapTxt;
    }

    override function update(stage : Stage):Void {
        super.update( stage );

        if (lt == null) {
            lt = now();
        }
        else {
            if ((now() - lt) >= 1000) {
                refresh();

                lt = now();
            }
            else {
                //
            }
        }
    }

    override function calculateGeometry(r : Rect<Float>):Void {
        super.calculateGeometry( r );
        var hr = hud.rect;

        y = (prev.y + prev.h + 3.5);
        x = (hr.x + hr.w - w - margin);
    }

    override function getEnabled():Bool {
        return true;
    }

    private var pid : Int;
    //private var prev : TextualHUDItem;
    //private var refreshTimer:Timer;
    private var metrics : Null<ProcessMetric>;
    private var memTotal : Null<Int>;

    private var lt: Null<Float>;

/* === Statics === */

    private static var JS_MAX_HEAP:Int = {(20 * 1024 * 1024);};
}
