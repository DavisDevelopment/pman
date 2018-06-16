package pman.display.media.audio;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.AudioNode;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;

class SplitAudioByFrequencyRangeNode extends AudioPipelineNode {
    /* Constructor Function */
    public function new(pl:AudioPipeline, ranges:Array<FrequencyRange>):Void {
        super(pl);

        this.ranges = ranges;
        rdn = new Dict();
        this.rnodes = [];

        //getContainingFrequencyRanges = getContainingFrequencyRanges.memoize();
    }

/* === Instance Methods === */

    override function init() {
        super.init();

        inline function iso(range) {
            return new FrequencyRangeIsolatorNode(pipeline, range);
        }

        inline function mk(range) {
            return rnodes[rnodes.push(rdn[range] = iso(range)) - 1];
        }

        var ig, og;
        ig = pipeline.context.createGain();
        og = pipeline.context.createGain();

        setNode(cast ig, cast og);

        if (rnodes.empty() && !ranges.empty()) {
            for (r in ranges) {
                mk(r).init();
            }
        }
    }

    /**
      initialize our isolator nodes and patch them into the pipeline
     **/
    override function _afterConnect(next: AudioPipelineNode) {
        var i = input(), o = output(), no;
        // disconnect [input] from [output]
        try
            i.disconnect( o )
        catch (e: js.html.DOMException) {
            null;
        }

        // connect [input] to freq-range isolators
        for (node in rnodes) {
            if (!node.isInitted())
                node.init();

            no = node.input();
            if (no == null)
                throw 'Error: No input node defined for range-isolator node';
            i.connect( no );

            // connect isolators back to [output]
            no.connect( o );
        }

        // now, the pipeline is still intact
    }

    public function getFrequencyRangeNodes():Array<FrequencyRangeIsolatorNode> {
        return rnodes;
    }

    public function getNodeForFrequencyRange(range: FrequencyRange):Null<FrequencyRangeIsolatorNode> {
        return rdn.get( range );
    }

    public function getFrequencyRanges():Array<FrequencyRange> {
        return ranges;
    }

    /**
      get list of ranges that contain [n]
     **/
    dynamic public function getContainingFrequencyRanges(n: Float):Array<FrequencyRange> {
        var frl = ranges.filter.fn(_.contains( n ));
        frl.sort.fn(_1.compareTo(_2));
        return frl;
    }

    /**
      get the nodes that isolate a frequency range that [freq] is within the bounds of
     **/
    public function getNodesForFrequency(freq: Float):Array<FrequencyRangeIsolatorNode> {
        return ranges.filter.fn(_.contains(freq)).map.fn(rdn[_]).compact();
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var ranges: Array<FrequencyRange>;
    public var rdn: Dict<FrequencyRange, FrequencyRangeIsolatorNode>;
    public var rnodes: Array<FrequencyRangeIsolatorNode>;
}
