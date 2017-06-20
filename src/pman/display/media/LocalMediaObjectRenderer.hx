package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;

import pman.core.*;
import pman.media.*;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * base-class for all MediaRenderer implementations making use of a MediaObject
  */
class LocalMediaObjectRenderer <T : MediaObject> extends MediaRenderer {
	/* Constructor Function */
	public function new(m:Media, c:MediaController):Void {
		super( m );

		this.mediaController = c;

		_av = null;
		audioManager = new AudioManager(untyped this);
	}

/* === Instance Methods === */

	/**
	  * unlink and deallocate [this]'s memory
	  */
	override function dispose():Void {
		super.dispose();

		m.destroy();
	}

	/**
	  * attach a visualizer to [this]
	  */
	public function attachVisualizer(v:AudioVisualizer, done:Void->Void):Void {
	    detachVisualizer(function() {
	        v.attached(function() {
	            visualizer = v;
	            done();
	        });
	    });
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

/* === Computed Instance Fields === */

	// more specifically-typed reference to [mediaController]
	private var tc(get, never):LocalMediaObjectPlaybackDriver<T>;
	private inline function get_tc():LocalMediaObjectPlaybackDriver<T> {
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
    public var audioManager : AudioManager;
}
