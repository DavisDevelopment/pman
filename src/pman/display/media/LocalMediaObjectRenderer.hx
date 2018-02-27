package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;

import pman.core.*;
import pman.media.*;

import electron.Tools.defer;
import Std.*;
import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

/**
  * base-class for all MediaRenderer implementations making use of a MediaObject
  */
class LocalMediaObjectRenderer <T : MediaObject> extends MediaRenderer {
	/* Constructor Function */
	public function new(m:Media, c:MediaController):Void {
		super( m );

		this.mediaController = c;

		_av = null;
		audioManager = new AudioPipeline(untyped this);
	}

/* === Instance Methods === */

	/**
	  * unlink and deallocate [this]'s memory
	  */
	override function dispose():Void {
		super.dispose();

		audioManager.deactivate();
		m.destroy();
	}

    /**
      * when [this] is attached to player view
      */
	override function onAttached(pv : PlayerView):Void {
	    buildAudioPipeline(function(?error) {
	        if (error != null)
	            report( error );
	    });
	}

    /**
      * when [this] is detached from player view
      */
	override function onDetached(pv : PlayerView):Void {
	    super.onDetached( pv );
	}

	/**
	  * attach a visualizer to [this]
	  */
	public function attachVisualizer(v:AudioVisualizer, done:Void->Void):Void {
	    done = done.wrap(function(f) {
	        _addComponent(new AudioEqualizer());
	        _attach_components( pman.Globals.player.view );
	        f();
	    })
	    .wrap(function(f) {
	        defer( f );
	    });

        var steps:Array<VoidAsync> = [];
        inline function step(a: VoidAsync) steps.push( a );

        //step(fn(destroyAudioPipeline( _ )));
        step(fn(detachVisualizer(_.void())));

        if (audioManager == null || !audioManager.active) {
            step(fn(buildAudioPipeline( _ )));
        }
        
        step(fn(v.attached(_.void())));
        step(function(next) {
            visualizer = v;
            visualizer.player = player;

            next();
        });

        steps.series(function(?error) {
            if (error != null) {
                report( error );
            }
            else {
                done();
            }
        });

        /*
	    detachVisualizer(function() {
	        audioManager.activate(function() {
                v.attached(function() {
                    visualizer = v;

                    // kick shit off
                    done();
                });

            });
	    });
	    */
	}
	private function _attach_components(pv: PlayerView):Void {
	    super.onAttached( pv );
	}

	/**
	  * detach the current visualizer
	  */
	public function detachVisualizer(done : Void->Void):Void {
	    if (visualizer != null) {
	        visualizer.detached(function() {
	            visualizer = null;
	            done();
	        });
	    }
        else {
            defer( done );
        }
	}

    private var bapCount:Int = 0;
	public function buildAudioPipeline(done: VoidCb):Void {
	    audioManager.activate(function() {
			//defer(done.void());

	        ++bapCount;
            if (bapCount == 2) {
				//throw 'Called Twice. What the fuck';
	        }
            else {
                window.console.error('Betty, why');
            }

            /*
	        if (bapCount == 1) {
	            throw 'Called. Oh yai';
	        }
            else if (bapCount == 2) {
	            throw 'Called Twice. What the fuck';
	        }
            else if (bapCount == 3) {
                throw 'Get the urinal';
            }
            */
            done();
	    });
		//throw 'build-audio-pipeline';
	}

	public function destroyAudioPipeline(done: VoidCb):Void {
	    audioManager.deactivate(done.void());
	}

	override function _addComponent(c: MediaRendererComponent):Void {
	    super._addComponent( c );
	    c.renderer = cast this;
	}

/* === Computed Instance Fields === */

	// more specifically-typed reference to [mediaController]
	private var tc(get, never):LocalMediaObjectMediaDriver<T>;
	private inline function get_tc():LocalMediaObjectMediaDriver<T> {
		return cast mediaController;
	}

	// shorthand reference to the mediaObject being rendered
	private var mediaObject(get, never):T;
	private inline function get_mediaObject():T return tc.m;

	// shorthand reference to the mediaObject being rendered
	private var m(get, never):T;
	private inline function get_m():T return tc.m;

	public var visualizer(get, set):Null<AudioVisualizer>;
	private inline function get_visualizer():Null<AudioVisualizer> return _av;
	private inline function set_visualizer(v : Null<AudioVisualizer>):Null<AudioVisualizer> {
	    return (_av = v);
	}

/* === Instance Fields === */

    public var _av : Null<AudioVisualizer>;
    public var audioManager : AudioPipeline;
}
