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
import pman.display.media.CircleBasedVisualizer;
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

class LayeredCircleVisualizer extends CircleBasedVisualizer {
    /* Constructor Function */
    public function new(r) {
        super(r);
    }

/* === Instance Methods === */

    override function build_tree(done: VoidCb):Void {
        ranges = new Array();
        inline function range(x, y) {
            return ranges[ranges.push(new FrequencyRange(x, y)) - 1];
        }

        var subBass = range(20, 60);
        var bass = range(60, 250);
        var midlow = range(250, 500);
        var mid = range(500, 2000);
        var midhigh = range(2000, 4000);
        var presence = range(4000, 6000);
        var brilliance = range((6*1000), (20*1000));

        frsplitter = new SplitAudioByFrequencyRangeNode(mr.audioManager, ranges);
        mr.audioManager.prependNode( frsplitter );
    }

/* === Instance Fields === */

    var ranges: Array<FrequencyRange>;
    var frsplitter: SplitAudioByFrequencyRangeNode;
}
