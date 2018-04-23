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
import pman.GlobalMacros.*;

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
        audioEq = new AudioEqualizer();

        //_req(next -> _addComponents([audioManager, audioEq], next));
	}

/* === Instance Methods === */

	/**
	  * unlink and deallocate [this]'s memory
	  */
	override function dispose(callback: VoidCb):Void {
		super.dispose( callback );
	}

    /**
      * when [this] is attached to player view
      */
    override function onAttached(pv:PlayerView, done:VoidCb):Void {
        vsequence(function(add, exec) {
            add(_superOnAttached.bind(pv, _));
            add(function(next) {
                _addComponents([
                    audioManager,
                    audioEq
                ], next);
            });
            add( linkAudioVisualizer );

            exec();
        }, done);
    }
    private function _superOnAttached(pv:PlayerView, cb:VoidCb):Void {
        super.onAttached(pv, cb);
    }

    /**
      * when [this] is detached from player view
      */
	override function onDetached(pv:PlayerView, done:VoidCb):Void {
	    audioManager = null;
	    audioEq = null;
	    _av = null;

	    super.onDetached(pv, done);
	}

	/**
	  * attach a visualizer to [this]
	  */
	public function attachVisualizer(v:AudioVisualizer, ?done:VoidCb):Void {
	    v.player = player;
	    if (done == null)
	        done = VoidCb.noop;

	    _addComponent(v, function(?error) {
	        visualizer = v;
	        done( error );
	    });
	}

	/**
	  * handle the linking of the audio-visualizer
	  */
	private function linkAudioVisualizer(done: VoidCb):Void {
	    vsequence(function(add, exec) {
	        if (_shouldShowAudioVisualizer()) {
	            var av:AudioVisualizer = _createAudioVisualizer();

	            if (av != null) {
	                add(function(next) {
                        attachVisualizer(av, next);
	                });
					//add(cast attachVisualizer.bind(av, _));
	            }
	        }

			//defer(() -> exec());
			exec();
	    }, done);
	}

    /**
      * create AudioVisualizer instance to be attached to [this]
      */
    public function _createAudioVisualizer():Null<AudioVisualizer> {
        return null;
    }

    /**
      * compute whether to render the AudioVisualizer or not
      */
    public function _shouldShowAudioVisualizer():Bool {
        return false;
    }

    /*
	public function attachVisualizer_(v:AudioVisualizer, done:Void->Void):Void {
	    done = done.wrap(function(f) {
	        defer( f );
	    });

        var steps:Array<VoidAsync> = [];
        inline function step(a: VoidAsync) steps.push( a );

        // detach the audio visualizer
        step(fn(detachVisualizer(_.void())));

        // build the audio pipeline
        //if (audioManager == null || !audioManager.active) {
            //step(fn(buildAudioPipeline( _ )));
        //}
        
        // 'attach' the given visualizer
        step(function(next) {
            visualizer = v;
            visualizer.player = player;

            next();
        });
        step(fn(v.attached(_.void())));

        // execute the steps
        whenAttached(function() {
            steps.series(function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    done();
                }
            });
        });
	}
	*/

	/**
	  * attach components to [this]
	  */
	private function _attach_components(pv:PlayerView, done:VoidCb):Void {
	    super.onAttached(pv, done);
	}

	/**
	  * detach the current visualizer
	  */
	public function detachVisualizer(done : VoidCb):Void {
	    if (visualizer != null) {
	        visualizer.detached(function(?error) {
	            visualizer = null;
	            done( error );
	        });
	    }
        else {
            defer( done );
        }
	}

    /**
      * build out the AudioPipeline for [this]
      */
	public function buildAudioPipeline(done: VoidCb):Void {
	    throw 'cheeks';
	    audioManager.activate(function(?error) {
            done( error );
	    });
	}

    /**
      * destroy the Audio Pipeline
      */
	public function destroyAudioPipeline(done: VoidCb):Void {
	    throw 'cheeks';
	    audioManager.deactivate( done );
	}

    /**
      * add a MediaRendererComponent to [this]
      */
	override function _addComponent(c:MediaRendererComponent, done:VoidCb):Void {
	    c.renderer = cast this;
	    c.player = player;
	    super._addComponent(c, done);
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
    public var audioEq: AudioEqualizer;
}
