package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;

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

class AudioVisualizer {
    /* Constructor Function */
    public function new(r : Mor):Void {
        renderer = r;
    }

/* === Instance Methods === */

    /**
      * render visualization
      */
    public function render(stage:Stage, c:Ctx):Void {

    }

    /**
      * update data associated with visualization
      */
    public function update(stage : Stage):Void {

    }

    /**
      * called when [this] gets attached to the media renderer
      */
    public function attached(done : Void->Void):Void {
        build_tree(function() {
            var win = tannus.html.Win.current;
            win.expose('visualizer', this);
            this.definePointer('fftSize', Ptr.create( fftSize ));
            this.definePointer('smoothing', Ptr.create( smoothing ));

            done();
        });
    }

    /**
      * called when [this] gets detached from the media renderer
      */
    public function detached(done : Void->Void):Void {
        context.close(function() {
            var win = tannus.html.Win.current;
            win.unexpose('visualizer');
            done();
        });
    }

	/**
	  * Configure [this] AudioVisualizer
	  */
	public inline function config(fftSize:Int=2048, smoothing:Float=0.8):Void {
		this.fftSize = fftSize;
		this.smoothing = smoothing;
	}

    /**
      * build out the audio analysis tree
      */
    private function build_tree(cb : Void->Void):Void {
        /* == Build Nodes == */
		context = new AudioContext();
		var c = context;
		
		source = c.createSource( mediaObject );
		splitter = c.createChannelSplitter( 2 );
		merger = c.createChannelMerger( 2 );
		leftAnalyser = c.createAnalyser();
		rightAnalyser = c.createAnalyser();

		/* == Connect Nodes == */
		source.connect( splitter );
		splitter.connect(leftAnalyser, [0]);
		splitter.connect(rightAnalyser, [1]);
		leftAnalyser.connect(merger, [0, 0]);
		rightAnalyser.connect(merger, [0, 1]);
		merger.connect( context.destination );

		config();

		defer( cb );
    }

/* === Computed Instance Fields === */

    public var controller(get, never):MediaController;
    private inline function get_controller():MediaController return renderer.mediaController;

    public var mediaObject(get, never):MediaObject;
    @:access( pman.display.media.LocalMediaObjectRenderer )
    private inline function get_mediaObject():MediaObject return untyped renderer.mediaObject;

    private var mo(get, never):MediaObject;
    private inline function get_mo():MediaObject return mediaObject;

    private var mc(get, never):MediaController;
    private inline function get_mc():MediaController return controller;

    private var mr(get, never):Mor;
    private inline function get_mr():Mor return renderer;

    public var fftSize(get, set):Int;
	private inline function get_fftSize():Int return leftAnalyser.fftSize;
	private inline function set_fftSize(v : Int):Int {
	    configChanged = true;
		return (leftAnalyser.fftSize = rightAnalyser.fftSize = v);
	}

	public var smoothing(get, set):Float;
	private inline function get_smoothing():Float return leftAnalyser.smoothing;
	private inline function set_smoothing(v : Float):Float {
	    configChanged = true;
	    return (leftAnalyser.smoothing = rightAnalyser.smoothing = v);
    }

/* === Instance Fields === */

    public var renderer : Mor;
    public var player : Null<Player> = null;

    public var context : AudioContext;
    public var source : AudioSource;
    public var splitter : AudioChannelSplitter;
    public var merger : AudioChannelMerger;
    public var leftAnalyser : AudioAnalyser;
    public var rightAnalyser : AudioAnalyser;

    private var configChanged:Bool = false;
}

private typedef Mor = Lmor<MediaObject>;
