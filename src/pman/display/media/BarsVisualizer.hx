package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.html.Win;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
import pman.display.media.AudioPipeline;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class BarsVisualizer extends AudioVisualizer {
    /* Constructor Function */
    public function new(r) {
        super( r );
    }

/* === Instance Methods === */

    /**
      * update [this] Visualizer
      */
    override function update(stage: Stage):Void {
        super.update( stage );
    }

    /**
      * render [this] Visualization
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);


        var r = viewport;
        c.clearRect(r.x, r.y, r.w, r.h);

        bars(stage, c);
    }

    /**
      * draw the bars for [this] Visualization
      */
    private function bars(stage:Stage, c:Ctx):Void {
        pullData();

        if (data != null) {
            c.save();

            var rect = viewport;
            var bufferLength:Int = analyzer.frequencyCount;
            var barWidth:Float = ((rect.width / bufferLength) + 1.0);
            var padding:Float = 0.0;
            var barHeight:Float;
            var barX:Float = 0.0;
            var index:Int = 0;
            var color:Color = new Color(255, 255, 50);

            while (index < bufferLength) {
                barHeight = ceil(data[index]);
                
                /*
                c.fillStyle = color(
                    barHeight + (25 * (index / bufferLength)),
                    250 * (index / bufferLength),
                    50
                );
                */
                color.red = floor(barHeight + (25 * (index / bufferLength)));
                color.green = floor(250 * (index / bufferLength));

                c.fillStyle = color;
                c.fillRect(floor(rect.x + barX), floor(rect.y + rect.height - barHeight), barWidth, barHeight);


                barX += floor(barWidth + padding);
                index++;
            }

            c.restore();
        }
    }

    /**
      * create and return a color string
      */
    private inline function color(r:Float, g:Float, b:Float):String {
        return 'rgb($r, $g, $b)';
    }

    /**
      * override that [build_tree] method
      */
    override function build_tree(done: Void->Void):Void {
        /*
        mr.audioManager.treeBuilders = [function(m : AudioManager) {
            var c = this.context = m.context;
            source = m.source;
            destination = m.destination;

            analyzer = c.createAnalyser();

            source.connect( analyzer );
            analyzer.connect( destination );

            config(1024, 0.65);
        }];
        mr.audioManager.buildTree( done );
        */

        var vizNode = mr.audioManager.createNode({
            init: function(self: Fapn) {
                var m = self.pipeline;
                var c = context = m.context;
                source = m.source;
                destination = m.destination;

                analyzer = c.createAnalyser();

                self.setNode(cast analyzer);

                config(1024 * 2, 0.65);
            } 
        });
        mr.audioManager.prependNode( vizNode );
        done();
    }

    /**
      * pull data
      */
    private function pullData():Void {
        var shouldPull:Bool = (configChanged || player.getStatus().match(Playing));
        if ( shouldPull ) {
            data = analyzer.getByteFrequencyData();
        }
    }

/* === Computed Instance Fields === */

    override function get_fftSize():Int return analyzer.fftSize;
    override function set_fftSize(v):Int {
        configChanged = true;
        return (analyzer.fftSize = v);
    }

    override function get_smoothing():Float return analyzer.smoothing;
    override function set_smoothing(v):Float {
        configChanged = true;
        return (analyzer.smoothing = v);
    }

/* === Instance Fields === */

    private var analyzer : AudioAnalyser;
    private var data: Null<AudioData<Int>>;
}
