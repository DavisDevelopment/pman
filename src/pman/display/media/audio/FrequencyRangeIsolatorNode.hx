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

class FrequencyRangeIsolatorNode extends AudioPipelineNode {
    /* Constructor Function */
    public function new(pipeline:AudioPipeline, range:FrequencyRange):Void {
        super( pipeline );

        this.range = range;
        anal = null;
    }

/* === Instance Methods === */

    override function init() {
        super.init();
        
        low = pipeline.context.createBiquadFilter();
        low.type = Lowpass;
        low.gain = -1;
        low.frequency = range.min;

        high = pipeline.context.createBiquadFilter();
        high.type = Highpass;
        high.gain = -1;
        high.frequency = range.max;

        gn = pipeline.context.createGain();
        
        low.connect( high );
        high.connect( gn );

        setNode(cast low, cast gn);
    }

    /**
      obtain a reference to an audio analyzer connected to [this]'s output-node
     **/
    public function analyze():AudioAnalyser {
        if (anal == null) {
            if (!isInitted()) {
                throw 'Cannot invoke "analyze" before Node has been added to the pipeline';
            }

            anal = pipeline.context.createAnalyser();
            (output()).connect( anal );
        }

        return anal;
    }

/* === Computed Instance Fields === */

    public var gain(get, set): Float;
    private inline function get_gain() return tqm(gn, _.gain, 0.0);
    private inline function set_gain(v) return tqm(gn, (_.gain = v), v);

/* === Instance Fields === */

    public var range: FrequencyRange;

    var low: AudioBiquadFilter;
    var high: AudioBiquadFilter;
    var gn: AudioGain;

    var anal: Null<AudioAnalyser>;
}
