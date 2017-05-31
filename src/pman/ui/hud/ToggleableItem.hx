package pman.ui.hud;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.*;

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

class ToggleableItem extends PlayerHUDItem {
    /* Constructor Function */
    public function new(hud : PlayerHUD):Void {
        super( hud );

        tb = new TextBox();
        tb.fontFamily = 'Ubuntu';
        tb.fontSize = 25;
        tb.fontSizeUnit = 'px';
        tb.color = new Color(255, 255, 255);

        toggleFields = [
            new ToggleField(this, 'muted', 'change:muted', Getter.create(player.muted?'yes':'no')),
            new ToggleField(this, 'shuffle', 'change:shuffle', Getter.create(player.shuffle?'yes':'no')),
            new ToggleField(this, 'speed', 'change:speed', Getter.create(round(player.playbackRate*100)+'%')),
            new ToggleField(this, 'volume', 'change:volume', Getter.create(round(player.volume * 100)+'%')),
            new ToggleField(this, 'scale', 'change:scale', Getter.create(round(player.scale * 100)+'%'))
        ];
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

        // get the most recent field
        mrf = toggleFields.min.fn(_.since());

        if (mrf != null) {
            tb.text = ('${mrf.name}: ${mrf.ref.get()}');
        }
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if (enabled && player.track != null) {
            c.drawComponent(tb, 0, 0, tb.width, tb.height, x, y, w, h);
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        var hr = hud.rect;

        w = tb.width;
        h = tb.height;
        x = (hr.x + hr.w - w - margin);
        y = margin;

        super.calculateGeometry( r );
    }

    /**
      * get whether [this] is enabled
      */
    override function getEnabled():Bool {
        if (mrf == null) {
            return false;
        }
        else {
            var smrf:Float = mrf.since();
            return (smrf <= duration);
        }
    }

/* === Instance Fields === */

    private var tb : TextBox;
    private var toggleFields : Array<ToggleField>;
    private var mrf : Null<ToggleField>=null;
}

private class ToggleField {
    private var i : ToggleableItem;
    public var event : String;
    public var name : String;
    public var ref : Getter<Dynamic>;

    public function new(i:ToggleableItem, name:String, event:String, ref:Getter<Dynamic>):Void {
        this.i = i;
        this.name = name;
        this.event = event;
        this.ref = ref;
    }

    /**
      * get the time that has elapsed since the last occurrence of [this]
      */
    public function since():Float {
        return (now - (i.player.getMostRecentOccurrenceTime( event )).ternary(_.getTime(), 0));
    }
}
