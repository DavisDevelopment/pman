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

import electron.ext.App;
import electron.ext.ExtApp.MemoryInfo;

import tannus.math.TMath.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.Tools;

class MemoryUsageDisplay extends TextualHUDItem {
    public function new(hud:PlayerHUD, prev:TextualHUDItem) {
        super( hud );

        tb.color = prev.tb.color;
        tb.multiline = true;

        this.prev = prev;
        refreshTimer = new Timer(1.2, refresh);
        pid = (untyped __js__('process.pid'));
        memInfo = null;

        refresh();
    }

    private function refresh():Void {

        if (memTotal == null) {
            memTotal = tannus.node.Os.totalmem();
        }

        var mi:Maybe<{pid:Int,memory:MemoryInfo}> = App.getAppMemoryInfo().firstMatch.fn(_.pid == pid);
        if (mi != null) {
            memInfo = mi.memory;
        }
        else return ;

        var big = memInfo.workingSetSize * 1000;
        var small = memInfo.privateBytes * 1000;

        tb.text = [
            ('$big / $memTotal (${Percent.percent(big, memTotal)})')
        ].join('\n');
    }

    override function update(stage : Stage):Void {
        super.update( stage );

        refreshTimer.tick();
    }

    override function calculateGeometry(r : Rectangle):Void {
        super.calculateGeometry( r );
        var hr = hud.rect;

        y = (prev.y + prev.h + 3.5);
        x = (hr.x + hr.w - w - margin);
    }

    override function getEnabled():Bool {
        return true;
    }

    private var pid : Int;
    private var prev : TextualHUDItem;
    private var refreshTimer:Timer;
    private var memInfo : Null<MemoryInfo>;
    private var memTotal : Null<Int>;
}
