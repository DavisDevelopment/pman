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
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TextualHUDItem extends PlayerHUDItem {
    public function new(hud : PlayerHUD):Void {
        super( hud );

        tb = new TextBox();
        tb.color = new Color(255, 255, 255);
        tb.fontSizeUnit = 'px';
    }

    private function getTextRect():Rectangle {
        return new Rectangle(x, y, tb.width, tb.height);
    }

    private function shouldRenderText():Bool return enabled;

    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if (shouldRenderText()) {
            var tr = getTextRect();
            c.drawComponent(tb, 0, 0, tb.width, tb.height, tr.x, tr.y, tr.w, tr.h);
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
        y = (hr.y + margin);

        super.calculateGeometry( r );
    }

    private var tb : TextBox;
}
