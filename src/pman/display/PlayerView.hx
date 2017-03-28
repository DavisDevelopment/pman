package pman.display;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.media.*;
import pman.ui.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PlayerView extends Ent {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();
		
		player = p;
		controls = new PlayerControlsView( this );
		addSibling( controls );
		messageBoard = new PlayerMessageBoard( player );
		addSibling( messageBoard );

		currentMediaRenderer = null;
	}

/* === PMan Methods === */

	/**
	  * detach the current renderer from [this] view, and deallocate its memory
	  */
	public function detachRenderer():Void {
		// if [this] view even has media
		if (currentMediaRenderer != null) {
			// alert the renderer that it is being detached
			currentMediaRenderer.onDetached( this );
			// deallocate that media
			currentMediaRenderer.dispose();

			// unlink it from [this] Object
			currentMediaRenderer = null;
		}
	}

	/**
	  * attach the given renderer to [this] view
	  */
	public function attachRenderer(mr : MediaRenderer):Void {
		// if [mr] isn't already attached to [this] view
		if (mr != currentMediaRenderer) {
			// if [this] view already has an attached renderer
			if (currentMediaRenderer != null) {
				// unlink it
				detachRenderer();
			}

			// now link the new one
			currentMediaRenderer = mr;
			currentMediaRenderer.onAttached( this );
		}
	}

/* === Gryffin Methods === */

	/**
	  * Update [this]
	  */
	override function update(stage : Stage):Void {
		// echo the playback properties onto the current media
		if (cmr != null) {
			// get a reference to the media's controller
			var mc = player.session.playbackDriver;
			var pp = player.session.pp;

			// copy the data over
			mc.setVolume( pp.volume );
			mc.setPlaybackRate( pp.speed );

			cmr.update( stage );

            // handle automatic skipping
            var currentStatus = player.getStatus();
            switch ( currentStatus ) {
                case PlayerStatus.Ended:
                    var ls = lastStatus;
                    player.gotoNext({
                        ready: function() {
                            switch ( ls ) {
                                case PlayerStatus.Playing:
                                    player.play();

                                default:
                                    trace( ls );
                            }
                        }
                    });

                default:
                    lastStatus = currentStatus;
            }
		}

		super.update( stage );
	}

	/**
	  * Render [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
	    // clear [this]'s rect
	    c.clearRect(x, y, w, h);

		// if [this] view has media
		if (cmr != null) {
			// render that media
			cmr.render(stage, c);
		}
		
		// render everything else
		super.render(stage, c);
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		rect.cloneFrom( r );
		if ( controls.uiEnabled ) {
			h -= controls.h;
		}
		if (player.isPlaylistOpen()) {
			var plv = player.getPlaylistView();
			w -= plv.width;
		}
		
		super.calculateGeometry( r );

		if (cmr != null) {
			cmr.calculateGeometry( rect );
		}
	}

/* === Computed Instance Fields === */

	public var cmr(get, set):Null<MediaRenderer>;
	private inline function get_cmr():Null<MediaRenderer> return currentMediaRenderer;
	private inline function set_cmr(v : Null<MediaRenderer>):Null<MediaRenderer> return (currentMediaRenderer = v);

/* === Instance Fields === */

	public var player : Player;
	public var controls : PlayerControlsView;
	public var messageBoard : PlayerMessageBoard;

	public var currentMediaRenderer : Null<MediaRenderer>;

	private var lastStatus : Null<PlayerStatus> = null;
}
