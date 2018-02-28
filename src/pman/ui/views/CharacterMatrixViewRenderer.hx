package pman.ui.views;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;

import haxe.extern.EitherType as Either;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.ui.views.CharacterMatrixViewMacros.*;
import pman.GlobalMacros.nullOr;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;
using tannus.FunctionTools;

class CharacterMatrixViewRenderer extends Ent {
    /* Constructor Function */
    public function new(matrix: CharacterMatrixView):Void {
        super();

        this.matrix = matrix;
        this.canvas = this.matrix.canvas;

        priority = -1;
    }

/* === Instance Methods === */

    /**
      * Initialize [this] renderer
      */
    override function init(stage: Stage):Void {
        super.init( stage );
    }

    /**
      * update [this] renderer
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        if (matrix.isChanged()) {
            matrix.update( _repaint );
            _repaint = false;
        }

        w = canvas.width;
        h = canvas.height;
    }

    /**
      * render [this] matrix, poo sha
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        c.drawComponent(canvas, 0, 0, canvas.width, canvas.height, x, y, w, h);

        #if debug
        //drawDebugInfo( c );
        #end
    }

    /**
      * draw some debug information
      */
    private function drawDebugInfo(c:Ctx):Void {
        var m = matrix.getCharMetrics();
        if (m == null) {
            return ;
        }
        else {
            c.save();
            c.lineWidth = 0.75;
            c.strokeStyle = 'limegreen';
            var rr = matrix.calculateCanvasRect();
            for (y in 0...matrix.height) {
                c.moveTo(0, this.y + (y * rr.h));
                c.lineTo(this.x + (rr.width), this.y + (y * rr.h));
            }
            c.stroke();
            c.restore();
        }
    }

/* === Instance Fields === */

    public var matrix: CharacterMatrixView;
    public var canvas: Canvas;

    private var _repaint:Bool = false;
}
