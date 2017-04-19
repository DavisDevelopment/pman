package pman.ui;

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

import tannus.math.TMath.*;
import gryffin.Tools.*;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TopViewCanvasProgressBar extends CanvasProgressBar {
    override function calculateGeometry(r : Rectangle):Void {
        var vp = player.view.rect;

        super.calculateGeometry( r );
        w = vp.w;
        h = 20;
        y = vp.y;
        x = vp.x;
    }
}
