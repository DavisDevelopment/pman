package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.impl.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
//import pman.display.media.AudioPipeline;
import pman.display.media.audio.AudioPipeline;
import pman.display.media.audio.AudioPipelineNode;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;
using tannus.async.Asyncs;
using tannus.ds.AnonTools;
using pman.display.media.AudioVisualizerTools;

class AudioVisualizer extends MediaRendererComponent {
    /* Constructor Function */
    public function new(r : Mor):Void {
        super();

        renderer = r;
        viewport = new Rect();
        changed = new Set();
        cache = new Dict();

        vdat = null;
        anal = null;
        fftOpts = Mono({
            fftSize: 1024,
            smoothing: 0.0
        });

        dataSpec = Mono(Mono(UInt8TimeDomain));
    }

/* === Instance Methods === */

    /**
      * render visualization
      */
    final override function render(stage:Stage, c:Ctx):Void {
        if (shouldPaint()) {
            paint( c );

        }
    }

    /**
      * update data associated with visualization
      */
    override function update(stage : Stage):Void {
        viewport = player.view.rect;

        pullData();
    }

    /**
      * called when [this] gets attached to the media renderer
      */
    override function attached(done : VoidCb):Void {
        super.attached(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                build_tree(function(?error) {
                    if (error != null) {
                        done( error );
                    }
                    else {
                        initialize( done );
                    }
                });
            }
        });
    }

    /**
      initialize [this] Visualizer after it's been attached
     **/
    public function initialize(done: VoidCb):Void {
        if (anal != null && dataSpec != null) {
            config();
            pullData();

            done();
        }
        else {
            done();
        }
    }

    //var _paintedLastFrame:Bool = false;
    public function shouldPaint():Bool {
        return true;
    }

    public function paint(c: Ctx):Void {
        //TODO
    }

    /**
      * called when [this] gets detached from the media renderer
      */
    override function detached(done : VoidCb):Void {
        vdat = null;
        anal = null;

        super.detached( done );
    }

	/**
	  * Configure [this] AudioVisualizer
	  */
	public function config(?opts: Either<Either<Array<FFTConfig>, Chan<FFTConfig>>, FFTConfig>):Void {
		if (opts == null) {
		     opts = cast fftOpts;
		}

        if ((opts is Array<Dynamic>)) {
            var o:Array<Null<FFTConfig>> = cast opts;
            o = o.compact().filter.fn(isValidFFTConfig(_)).slice(0, 3);

            switch o {
                case []:
                    null;

                case [a]:
                    fftOpts = Mono(tweakFFTConfig(a));

                case [a, b]:
                    fftOpts = Duo(tweakFFTConfig(a), tweakFFTConfig(b));

                case [a, b, c]:
                    fftOpts = Trio(tweakFFTConfig(a), tweakFFTConfig(b), tweakFFTConfig(c));

                case _:
                    throw 'InvalidInput: $o';
            }

            commitConfig();
        }
        else if ((opts is Chan<FFTConfig>)) {
		    var o:Chan<Null<FFTConfig>> = cast opts;

		    return config(o.values());
		}
        else {
            return config(Mono(cast opts));
        }
	}

    /**
      apply the FFT config info to the audio analysers
     **/
	inline function commitConfig() {
	    switch ({a:anal, o:fftOpts}) {
            case {o:Mono(o), a:_}:
                anal.apply(a -> _configAnalyser(a, o));

            case {o:Duo(x,y), a:Duo(ax, ay)}:
                _configAnalyser(ax, x);
                _configAnalyser(ay, y);

            case {o:Trio(x,y,z), a:Trio(ax, ay, az)}:
                _configAnalyser(ax, x);
                _configAnalyser(ay, y);
                _configAnalyser(az, z);

            case other:
                throw 'TypeError: Config ${other.o} cannot be applied to ${other.a}';
	    }
	}

	inline function isValidFFTConfig(o: FFTConfig):Bool {
	    return (
	        o.fftSize.with(
                (_.inRange(32, 32768) || _.inRange(5, 15)) &&
                (_ % 32 == 0)
	        ) &&
	        o.smoothing.inRange(0.0, 1.0)
	    );
	}

    /**
      resolve any shortcut values or type quirks in the given FFTConfig so that its values can be transferred to the analyser unmodified
     **/
	inline function tweakFFTConfig(o: FFTConfig):FFTConfig {
	    if (o.fftSize.inRange(5, 15)) {
	        o.fftSize = int(pow(2, o.fftSize));
	    }
	    return o;
	}

    /**
      apply the given FFTConfig to the given AudioAnalyser
     **/
	inline function _configAnalyser(a:AudioAnalyser, o:FFTConfig) {
	    a.fftSize = o.fftSize;
	    a.smoothing = o.smoothing;
	}

    /**
      check whether data should be pulled from analysers
     **/
    var pulledDataLastFrame:Bool = false;
	inline function shouldPullData():Bool {
	    return vdat == null || (
			//!pulledDataLastFrame &&
	        !player.muted &&
	        (isChanged('config') || player.getStatus().match(Playing))
	    );
	}

    /**
      pull data from analysers
     **/
	inline function pullData():Void {
	    /* cancel operation if it should not have been started */
	    if (!shouldPullData()) {
	        pulledDataLastFrame = !pulledDataLastFrame;
	        return ;
        }

	    switch ({a:anal, d:dataSpec}) {
            case {a:Mono(a), d:Mono(dChan)}:
                vdat = Mono(pullSpecChan(dChan, a));

            case {a:Duo(l, r), d:Duo(lchan, rchan)}:
                vdat = Duo(pullSpecChan(lchan, l), pullSpecChan(rchan, r));

            case {a:Trio(l, m, r), d:Trio(lchan, mchan, rchan)}:
                vdat = Trio(pullSpecChan(lchan, l), pullSpecChan(mchan, m), pullSpecChan(rchan, r));

            case other:
                throw other;
	    }

        pulledDataLastFrame = !pulledDataLastFrame;

	    _onPull();
	}

	function _onPull() {
	    //TODO
	}

	inline function pullSpecChan(x:Chan<AudioDataSpec>, a:AudioAnalyser):Chan<EAudioData> {
	    return switch x {
            case Mono(x): Mono(ead(a, x));
            case Duo(x, y): Duo(ead(a, x), ead(a, y));
            case Trio(l, m, r): Trio(ead(a, l), ead(a, m), ead(a, r));
            default: throw x;
	    };
	}

    /**
      pull audio data
     **/
	inline function _extractAudioData<T:Float>(an:AudioAnalyser, spec:AudioDataSpec, ?d:AudioData<T>):EAudioData {
	    return switch spec {
            case UInt8Frequency: EUInt8(an.getByteFrequencyData(untyped d));
            case Float32Frequency: EFloat32(an.getFloatFrequencyData(untyped d));
            case UInt8TimeDomain: EUInt8(untyped an.getByteTimeDomainData(untyped d));
            case Float32TimeDomain: EFloat32(untyped an.getFloatTimeDomainData(untyped d));
	    };
	}
	inline function ead<T:Float>(a:AudioAnalyser, s:AudioDataSpec, ?d:AudioData<T>):EAudioData return _extractAudioData(a, s);

    /**
      * build out the audio analysis tree
      */
    private function build_tree(done : VoidCb):Void {
        var vizNode = mr.audioManager.createNode({
            init: function(self: Fapn) {
                var m = self.pipeline;
                var c = m.context;


                switch ( dataSpec ) {
                    /* one analyser node */
                    case Mono(_):
                        var monoAnalyser = c.createAnalyser();
                        self.setNode(cast monoAnalyser);
                        anal = Mono(monoAnalyser);

                    /* two analyser nodes */
                    case Duo(_, _):
                        var splitter = c.createChannelSplitter( 2 );
                        var merger = c.createChannelMerger( 2 );
                        var leftAnalyser = c.createAnalyser();
                        var rightAnalyser = c.createAnalyser();

                        splitter.connect(leftAnalyser, [0]);
                        splitter.connect(rightAnalyser, [1]);
                        leftAnalyser.connect(merger, [0, 0]);
                        rightAnalyser.connect(merger, [0, 1]);

                        self.setNode(cast splitter, cast merger);
                        anal = Duo(leftAnalyser, rightAnalyser);

                    /* three analyser nodes */
                    case Trio(_, _, _):
                        var monoAnalyser = c.createAnalyser();
                        var splitter = c.createChannelSplitter( 2 );
                        var merger = c.createChannelMerger( 2 );
                        var leftAnalyser = c.createAnalyser();
                        var rightAnalyser = c.createAnalyser();

                        monoAnalyser.connect( splitter );
                        splitter.connect(leftAnalyser, [0]);
                        splitter.connect(rightAnalyser, [1]);
                        leftAnalyser.connect(merger, [0, 0]);
                        rightAnalyser.connect(merger, [0, 1]);

                        self.setNode(cast monoAnalyser, cast merger);
                        anal = Trio(leftAnalyser, monoAnalyser, rightAnalyser);
                }
            }
        });

        mr.audioManager.prependNode( vizNode );
        config();
        done();
    }

    /**
      split the given String by semicolons
     **/
    inline static function _semiSplit(s: String):Array<String> {
        return (~/\s*;\s*/g).split( s ).map(x -> x.nullEmpty()).compact();
    }

    inline function touch(k: String) {
        changed.pushMany(_semiSplit( k ));
    }

    inline function untouch(s: String) {
        for (k in _semiSplit( s )) {
            changed.remove( k );
        }
    }

    inline function isChanged(k: String):Bool {
        return changed.exists( k );
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var anal: Null<Chan<AudioAnalyser>>;
    public var dataSpec: Chan<Chan<AudioDataSpec>>;
    public var fftOpts: Chan<FFTConfig>;
    public var vdat: Null<AVDataContainer>;

    var changed: Set<String>;
    var cache: Dict<String, Dynamic>;
}

private typedef Mor = Lmor<MediaObject>;

enum Chan<T> {
    Mono(x: T);
    Duo(x:T, y:T);
    Trio(a:T, b:T, c:T);
}

enum EAudioData {
    EUInt8(d: AudioData<Int>);
    EFloat32(d: AudioData<Float>);
}

/**
  enum of all types of AudioData to be extracted from Analyser
 **/
enum AudioDataSpec {
    UInt8Frequency;
    UInt8TimeDomain;
    Float32Frequency;
    Float32TimeDomain;
}

@:forward
abstract AVDataContainer (Chan<AVDataValue>) from Chan<AVDataValue> to Chan<AVDataValue> {
    
}

@:forward
abstract AVDataValue (Chan<EAudioData>) from Chan<EAudioData> to Chan<EAudioData> {

}

enum AudioDataNumType {
    ADNT_UInt8;
    ADNT_Float32;
}

enum AudioDataKind {
    FrequencyData;
    TimeDomainData;
}

typedef AudioDataSpecDecl = {
    var ntype: AudioDataNumType;
    var kind: AudioDataKind;
}

typedef FFTConfig = {
    var fftSize: Int;
    @:optional var smoothing: Float;
}
