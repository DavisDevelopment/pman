package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.html.Win;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.AudioVisualizer;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
import pman.ds.ProxyModel;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using pman.display.media.AudioVisualizerTools;

/**
  visualizes audio data via spectogram
 **/
class SpectographVisualizer extends AudioVisualizer {
    /* Constructor Function */
    public function new(r):Void {
        super( r );

        dataSpec = Trio(Mono(UInt8TimeDomain), Mono(UInt8TimeDomain), Mono(UInt8TimeDomain));

        colors = null;
    }

/* === Instance Methods === */

    /**
      * when [this] is attached to the Media
      */
    override function attached(done : VoidCb):Void {
        super.attached( done );
    }

    /**
      initialize [this]
     **/
    override function initialize(done: VoidCb):Void {
        config({
            fftSize: 512,
            smoothing: 0.0
        });

        done();
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        if (player.track.type.match( MTVideo )) {
            viewport = player.view.mediaRect;
            viewport.pull( player.view.statusBar.rect );
        }
    }

    /**
      * render [this]
      */
    override function paint(c: Ctx):Void {
        c.save();

        var r = viewport;
        c.clearRect(r.x, r.y, r.w, r.h);

        waveform( c );

        c.restore();
    }

    /**
      * draw the waveform
      */
    inline function waveform(c: Ctx):Void {
        var colors = getColors();

        if (vdat != null && vdat.isStereo()) {
            var stereo = vdat.getStereo().map(ed -> ed.toByteAudioData());
            var ldat = stereo[0], rdat = stereo[1];

            if ( solidRender ) {
                c.save();
                c.globalCompositeOperation = 'lighter';

                drawFilledWaveformPaths(c, [
                {
                    data: [ldat, ldat],
                    fillStyle: colors[0],
                    mod: [null, {value: invert}]
                },
                {
                    data: [rdat, rdat],
                    fillStyle: colors[2],
                    mod: [{value: diminish.bind(_, 0.22)}, {value: diminishedInvert.bind(_, 0.22)}]
                }
                ]);
                
                c.restore();
            }
            else if ( doubleRender ) {

                // draw the left-channel data
                drawWaveformPath(c, 1, colors[3], ldat);

                // draw the right channel data
                drawWaveformPath(c, 1, colors[1], rdat, {
                    value: invert
                });

                // draw the left-channel data
                drawWaveformPath(c, 2, colors[0], ldat, {
                    value: diminish.bind(_, 0.22)
                });

                // draw the right channel data
                drawWaveformPath(c, 2, colors[2], rdat, {
                    value: diminishedInvert.bind(_, 0.22)
                });

                // draw the left channel, inverted and diminished
                drawWaveformPath(c, 1, colors[3], ldat, {
                    value:  diminishedInvert.bind(_, 0.44)
                });

                // draw the right channel, diminished
                drawWaveformPath(c, 1, colors[1], rdat, {
                    value: diminish.bind(_, 0.44)
                });
            }
            else {
                // draw the left-channel data
                drawWaveformPath(c, 3, colors[0], ldat);

                // draw the right channel data
                drawWaveformPath(c, 3, colors[2], rdat, {
                    value: invert
                });
            }
        }
    }

    /**
      * divide the given AudioData into two AudioDatas
      */
    inline function split(d : AudioData<Int>):Pair<AudioData<Int>, AudioData<Int>> {
        var mid:Int = floor(d.length / 2);
        return new Pair(d.slice(0, mid), d.slice(mid));
    }

    /**
      * draw waveform path
      */
    inline function drawWaveformPath(c:Ctx, lineWidth:Float, strokeStyle:Dynamic, data:AudioData<Int>, ?mod:Mod):Void {
        c.beginPath();
        c.strokeStyle = strokeStyle;
        c.lineWidth = lineWidth;
        drawAudioDataVertices(data, c, mod);
        c.stroke();
    }

    /**
      * draw a filled waveform path
      */
    inline function drawFilledWaveformPaths(c:Ctx, paths:Array<FwpDecl>):Void {
        for (w in paths) {
            c.beginPath();
            c.fillStyle = w.fillStyle;
            
            drawAudioDataPairVertices(w.data, c, w.mod);

            c.closePath();
            c.fill();
        }
    }

	/**
	  * draw the spectograph for the given AudioData, onto the given Ctx
	  */
	public function drawAudioDataVertices(data:AudioData<Int>, c:Ctx, ?mod:Mod, chained:Bool=false, reverse:Bool=false):Void {
		var mid:Float = viewport.centerY;
		var sliceWidth:Float = (ceil( viewport.width ) * 1.0 / data.length);
		var offset:Float, value:Int, n:Float, x:Float=(reverse?viewport.width:0), y:Float;
		var i:Int = (reverse ? data.length - 1 : 0);

		while ((reverse ? i >= 0 : i < data.length)) {
			offset = ((data.length / 2) - abs((data.length / 2) - i));
			offset = (offset / (data.length / 2));
			if (mod != null && mod.offset != null) {
				offset = mod.offset( offset );
			}

			value = data[i];
			if (mod != null && mod.value != null) {
				value = mod.value( value );
			}
			//n = (value / 128.0);
			y = (mid + (mid - ((value / 128.0) * mid)) * offset);
			(!chained && i == 0 ? c.moveTo : c.lineTo)(x, y);
			x += ((reverse ? -1 : 1) * sliceWidth);
			i += (reverse ? -1 : 1);
		}
	}

    /**
      * draw a pair of AudioData<Int> vertices as a single path
      */
	public function drawAudioDataPairVertices(datas:Array<AudioData<Int>>, c:Ctx, mods:Array<Null<Mod>>):Void {
	    var mid:Float = viewport.centerY;
	    var data:AudioData<Int> = datas[0], mod:Null<Mod> = mods[0];
	    var sliceWidth:Float = (ceil( viewport.width ) * 1.0 / data.length);
	    var offset:Float, value:Int, n:Float, x:Float=0, y:Float;
	    var i:Int = 0;

	    while (i < data.length) {
	        offset = ((data.length / 2) - abs((data.length / 2) - i));
	        offset = (offset / (data.length / 2));
	        if (mod != null && mod.offset != null) {
	            offset = mod.offset( offset );
	        }

	        value = data[i];
	        if (mod != null && mod.value != null) {
	            value = mod.value( value );
	        }

	        y = (mid + (mid - ((value / 128.0) * mid)) * offset);
	        if (i == 0) {
	            c.moveTo(x, y);
	        }
            else {
                c.lineTo(x, y);
            }

            x += sliceWidth;
            i++;
	    }

        data = datas[1];
        mod = mods[1];
	    i = data.length;
	    x = viewport.width;

	    while (i >= 0) {
	        offset = ((data.length / 2) - abs((data.length / 2) - i));
	        offset = (offset / (data.length / 2));
	        if (mod != null && mod.offset != null) {
	            offset = mod.offset( offset );
	        }

	        value = data[i];
	        if (mod != null && mod.value != null) {
	            value = mod.value( value );
	        }

	        y = (mid + (mid - ((value / 128.0) * mid)) * offset);
            c.lineTo(x, y);

            x -= sliceWidth;
            i--;
	    }
	}

	/**
	  * invert data
	  */
	private function invert(i : Int):Int {
	    return (255 - i);
	}

    /**
      * invert and diminish data
      */
	private function diminishedInvert(i:Int, amount:Float):Int {
	    return invert(diminish(i, amount));
	}

    /**
	  * used to decrease the magnitude of the waveform by 1/3
	  */
	private function diminish(value:Int, amount:Float):Int {
		var diff:Int = (128 - value);
		diff = floor(diff - (amount * diff));
		return (diff + 128);
	}

	/**
	  * get the color scheme of the waveform
	  */
	private function getColors():Array<String> {
		if (colors == null) {
			var base:Color = player.theme.secondary;
			var accent:Color = base.invert();
			var base2:Color = base.darken( 30 );
			var accent2:Color = accent.darken( 30 );

			colors = [base, base2, accent, accent2].map.fn(_.toString());
			return colors;
		}
		else {
		    return colors;
		}
	}

	/**
	  * get the viewport as a Rect
	  */
	private inline function getViewport():Rect<Float> {
	    return new Rect(vr.x, vr.y, vr.w, vr.h);
	}

/* === Computed Instance Fields === */

    private var vr(get, never):Rect<Float>;
    private inline function get_vr() return player.view.rect;

/* === Instance Fields === */

    private var colors:Null<Array<String>>;

    private var doubleRender:Bool = true;
    private var quadRender:Bool = true;
    private var solidRender:Bool = true;
}

// modifier for audio data rendering
typedef Mod = {
	?value : Int -> Int,
	?offset : Float -> Float
};

typedef FwpDecl = {
    data: Array<AudioData<Int>>,
    mod: Array<Null<Mod>>,
    fillStyle: Dynamic
}

