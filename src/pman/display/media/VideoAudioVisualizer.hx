package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
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
import pman.media.*;
import pman.display.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
//import pman.display.media.AudioPipeline;
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

class VideoAudioVisualizer extends AudioVisualizer {
    /* Constructor Function */
    public function new(r):Void {
        super( r );

        data = {
            d: null,
            left: null,
            right: null
        };

        anal = {
            a: null,
            left: null,
            right: null
        };

        vpr = {
            left: null,
            right: null
        };

        split = false;
        filled = false;

        style = Spectograph;
        audioDataType = TimeDomain;
    }

/* === Instance Methods === */

    /**
      * update [this] view, every frame
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        var mr = player.view.mediaRect;
        var fr = player.view.rect;
        
        if (mr.x != fr.x) {
            vpr.left = nullOr(vpr.left, new Rect());
            vpr.right = nullOr(vpr.right, new Rect());

            vpr.left.set(
                fr.x, max(mr.y, fr.y),
                (mr.x - fr.x), max(mr.h, fr.h)
            );

            vpr.right.set(
                (mr.x + mr.w), max(mr.y, fr.y),
                (fr.w - mr.w - (mr.x - fr.x)), max(mr.h, fr.h)
            );
        }

        if (!player.paused || (nullOr(data.d, data.left, data.right) == null)) {
            pullData();
        }

        pullConfig( pic );
    }

    /**
      * render [this] view
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if ( !pic.videoShowVisualizer ) {
            return ;
        }

        switch ( style ) {
            case Spectograph, CenterWeightedSpectograph:
                waveform(stage, c);

            case Bars:
                bars(stage, c);
        }
    }

    /**
      * draw bar-based visualization
      */
    private function bars(stage:Stage, c:Ctx):Void {
        //TODO
    }

    /**
      * draw spectogram visualization
      */
    private function waveform(stage:Stage, c:Ctx):Void {
        c.save();

        spectogram(nullOr(data.left, data.d), c, Left, null, new Color(255, 255, 255), 0.35);
        spectogram(nullOr(data.right, data.d), c, Right, null, new Color(255, 255, 255), 0.35);

        c.restore();
    }

    /**
      * draw a spectogram
      */
    private function spectogram(data:AudioData<Int>, c:Ctx, side:Side, ?mod:Mod, ?color:Color, ?lineWidth:Float):Void {
        qm(color, c.strokeStyle = _);
        qm(lineWidth, c.lineWidth = _);

        c.beginPath();
        drawSpectographVertices(data, c, side, mod);
        c.stroke();
    }

    /**
      * audio the lines that make up the spectogram
      */
    private function drawSpectographVertices(data:AudioData<Int>, c:Ctx, side:Side, ?mod:Mod):Void {
        inline function half(n:Float):Float return (n / 2);
        if (mod == null)
            mod = {};

        var bounds:Rect<Float>, basex:Float;
        switch ( side ) {
            case Left:
                bounds = vpr.left;
                basex = (bounds.x + bounds.width);

            case Right:
                bounds = vpr.right;
                basex = bounds.x;
        }

        var mid:Float = bounds.centerX;
        var sliceLen:Float = (bounds.height * 1.0 / data.length);
        var len:Int = data.length;
        var hl:Float = (len / 2);
        var offset:Float, value:Int, n:Float, x:Float;
        var y:Float = bounds.y;
        var i:Int = 0;

        inline function step(x:Float, y:Float) {
            if (i == 0) {
                c.moveTo(x, y);
            }
            else {
                c.lineTo(x, y);
            }
        }

        while (i < len) {
            // == offset
			value = data[i];
			if (mod.value != null) {
			    value = mod.value( value );
			}
			n = (value / 255.0);

			var offset:Float = (n * (bounds.width / 4) * (side == Left ? -1.0 : 1.0));

            //x = (basex + (n * half(bounds.centerX - bounds.x)));
            x = (basex + offset);
            //if (!isNaN( x ) && isFinite( x ) && x != basex) {
                //trace( x );
            //}

            step(x, y);

			y += sliceLen;
			++i;
        }
    }

    /**
      * get the [n] values for drawing the spectograph
      */
    private function getSpectographValues(data:AudioData<Int>, c:Ctx, side:Side, ?mod:Mod):Array<Float> {
        if (mod == null) mod = {};
        var index:Int = 0;
        var value:Int;
        var results:Array<Float> = new Array();
        while (index < data.length) {
            value = data[index];
            if (mod.value != null) {
                value = mod.value( value );
            }
            results.push(value / 255.0);
            ++index;
        }
        return results;
    }

    /**
      * build the audio-pipeline node that will feed us our audio data
      */
    override function build_tree(done: VoidCb):Void {
        var vizNode = mr.audioManager.createNode({
            init: function(self: Fapn) {
                var c = self.pipeline.context;
                if ( split ) {
                    if (self.pipeline.source.channelCount == 2) {
                        var splitter = c.createChannelSplitter( 2 );
                        var la = anal.left = c.createAnalyser();
                        var ra = anal.right = c.createAnalyser();
                        var merger = c.createChannelMerger( 2 );


                        splitter.connect(la, [0]);
                        splitter.connect(ra, [1]);
                        la.connect(merger, [0, 0]);
                        ra.connect(merger, [0, 1]);

                        self.setNode(cast splitter, cast merger);
                    }
                    else {
                        var anode = anal.a = c.createAnalyser();
                        var out = c.createGain();
                        anode.connect( out );
                        self.setNode(cast anode, cast out);
                    }
                }
                else {
                    var node = anal.a = c.createAnalyser();
                    var out = c.createGain();

                    node.connect( out );
                    self.setNode(cast node, cast out);
                    //self.setNode(cast (anal.a = c.createAnalyser()));
                }
            }
        });

        mr.audioManager.prependNode( vizNode );

        config();
        done();
    }

    /**
      * get data from the audio analysis nodes
      */
    private function pullData():Void {
        if (anal.a != null) {
            data.d = dataFrom( anal.a );
        }

        if (anal.left != null) {
            data.left = dataFrom( anal.left );
        }

        if (anal.right != null) {
            data.right = dataFrom( anal.right );
        }
    }

    /**
      * compute internal configuration properties
      */
    private function pullConfig(i: PlayerInterfaceConfiguration):Void {
        this.split = false;
        this.style = (switch ( i.videoVisualizerType ) {
            case 'bars': VAVisualizerStyle.Bars;
            case null, 'spectograph', 'default': VAVisualizerStyle.Spectograph;
            case 'center-spectograph': VAVisualizerStyle.CenterWeightedSpectograph;
            default: throw 'Why Tho';
        });

        this.audioDataType = (switch ( style ) {
            case Spectograph, CenterWeightedSpectograph: Frequency;
            case Bars: Frequency;
        });
    }

    /**
      * configure [this]'s analyser nodes
      */
    override function config(fftSize:Int=2048, smoothing:Float=0.6):Void {
        inline function set(a: AudioAnalyser) {
            a.fftSize = fftSize;
            a.smoothing = smoothing;
        }

        if (anal.a != null)
            set( anal.a );

        if (anal.left != null)
            set( anal.left );
        
        if (anal.right != null)
            set( anal.right );
    }

    /**
      * pull data from the given AudioAnalyser node
      */
    private function dataFrom(node:AudioAnalyser):AudioData<Int> {
        return (switch ( audioDataType ) {
            case TimeDomain: node.getByteTimeDomainData();
            case Frequency: node.getByteFrequencyData();
        });
    }

    /**
      * invert the given time-domain data
      */
    private static function invert(i: Int):Int return (255 - i);

/* === Computed Instance Fields === */

    public var pic(get, never): PlayerInterfaceConfiguration;
    private inline function get_pic() return player.conf;

/* === Instance Fields === */

    private var data: VizData;
    private var anal: VizAnalyzer;
    private var vpr: VizViewport;

    private var split:Bool;
    private var centered:Bool;
    private var filled:Bool;
    private var style:VAVisualizerStyle;
    private var audioDataType: VizAudioDataType;
}

typedef VizData = {
    ?d: AudioData<Int>,
    ?left: AudioData<Int>,
    ?right: AudioData<Int>
};

typedef VizAnalyzer = {
    ?a: AudioAnalyser,
    ?left: AudioAnalyser,
    ?right: AudioAnalyser
};

typedef VizViewport = {
    ?left: Rect<Float>,
    ?right: Rect<Float>
};

enum VAVisualizerStyle {
    Bars;
    Spectograph;
    CenterWeightedSpectograph;
}

@:enum
abstract VizAudioDataType (Bool) {
    var Frequency = true;
    var TimeDomain = false;
}

@:enum
private abstract Side (Bool) {
    var Left = false;
    var Right = true;
}

// modifier for audio data rendering
private typedef Mod = {
	?value : Int -> Int,
	?offset : Float -> Float
};
