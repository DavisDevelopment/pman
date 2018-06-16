package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.geom2.Angle;
import tannus.geom2.Arc;
import tannus.geom2.Velocity;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.html.Win;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.ds.FixedLengthArray;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
//import pman.display.media.AudioPipeline;
import pman.display.media.audio.*;
import pman.display.media.audio.AudioPipeline;
import pman.display.media.audio.AudioPipelineNode;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;

class CircleBasedVisualizer extends AudioVisualizer {
    /* Constructor Function */
    public function new(r) {
        super(r);
    }

    override function update(stage: Stage):Void {
        super.update( stage );
    }

/* === Instance Fields === */

    
}


/**
 **/
class Circle {
    /* Constructor Function */
    public function new(center:Point<Float>, radius:Float, segmentCount:Int) {
        this.center = center;
        this.radius = radius;
        this.segmentCount = segmentCount;
    }

/* === Instance Methods === */

    public function arcs():FixedLengthArray<Arc<Float>> {
        var l = fla();
        // divide full circle into [seqmentCount] pieces
        var ai = (360 / segmentCount);

        for (i in 0...segmentCount) {
            l.set(i, new Arc(center, radius, deg(i * ai), deg(ai)));
        }
        return l;
    }

    public function points():FixedLengthArray<Velocity> {
        var l:FixedLengthArray<Velocity> = fla(), ai = (360 / segmentCount);
        for (i in 0...segmentCount) {
            l.set(i, new Velocity(radius, deg(i * ai)));
        }
        return l;
    }

    inline function deg(n: Float):Angle return new Angle( n );
    private inline function fla<T>(?len: Int):FixedLengthArray<T> {
        return FixedLengthArray.alloc(nullOr(len, segmentCount));
    }

/* === Instance Fields === */

    public var center: Point<Float>;
    public var radius: Float;
    public var segmentCount: Int;
}


