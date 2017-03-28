package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PlayerControlsView extends Ent {
	/* Constructor Function */
	public function new(p : PlayerView):Void {
		super();

		playerView = p;

		uiEnabled = true;
		uiHideDelay = 3500;
		cidm = new Map();
		buttons = new Array();
		seekBar = new SeekBar( this );

		defer(function() {
			addButton(new PlaybackButton( this ));
			addButton(new ShuffleButton( this ));
			addButton(new PreviousButton( this ));

			addButton(new FullscreenButton( this ));
			addButton(new CastButton( this ));
			addButton(new VolumeButton( this ));
			addButton(new PlaybackSpeedButton( this ));
			addButton(new NextButton( this ));

			addChild( seekBar );
		});
	}

/* === Instance Methods === */

	/**
	  * draw [this] widget
	  */
	override function render(stage:Stage, c:Ctx):Void {
		// cancel render procedures immediately if ui is hidden
		if ( !uiEnabled ) {
			return ;
		}

		// draw the background
		c.save();

		/*
		if ( hovered ) {
			c.globalAlpha = 1.0;
		}
		else {
			c.globalAlpha = 0.75;
		}
		*/

		c.beginPath();
		c.drawRect( rect );
		c.closePath();
		c.fillStyle = getBackgroundColor().toString();
		c.fill();

		super.render(stage, c);

		//c.globalAlpha = 1.0;
		c.restore();

	}

	/**
	  * update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		var mp = stage.getMousePosition();
		hovered = (mp != null && containsPoint( mp ));
		var events = ['mousemove', 'click'];
		var times = events.map( stage.mostRecentOccurrenceTime  ).filter.fn(_ != null).map.fn(now - _);
		if (!times.empty()) {
			var last = times.min.fn( _ );
			uiEnabled = (hovered || last <= uiHideDelay);
		}

        if ( uiEnabled ) {
            if ( hovered ) {
                var ihovered:Bool = false;
                if ( seekBar.hovered ) {
                    ihovered = true;
                }
                else {
                    for (b in buttons) {
                        if ( b.hovered ) {
                            ihovered = true;
                            break;
                        }
                    }
                }

                if ( ihovered ) {
                    stage.cursor = 'pointer';
                }
                else {
                    stage.cursor = 'default';
                }
            }
            else {
                stage.cursor = 'default';
            }
        }
        else {
            stage.cursor = 'none';
        }
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		r = playerView.rect;
		w = r.w;
		h = 55;
		y = r.h;
		x = 0;

		__positionButtons();

		super.calculateGeometry( r );
	}

	/**
	  * add a Button to [this]
	  */
	public function addButton(b : PlayerControlButton):Void {
		buttons.push( b );
		addChild( b );

		calculateGeometry( rect );
	}

	/**
	  * calculate the positions of the Buttons
	  */
	private function __positionButtons():Void {
		var l:Array<PlayerControlButton> = [];
		var r:Array<PlayerControlButton> = [];
		for (btn in buttons) {
			if ( btn.enabled ) {
				(switch ( btn.btnFloat ) {
					case Left: l;
					case Right: r;
				}).push( btn );
			}
		}

		var padding:Float = 5.0;
		// base distance from bottom
		var bdfb:Float = 30;

		// position the left-floating buttons
		var c:Point = new Point((x + padding), ((y + h) - bdfb - padding));
		for (btn in l) {
			btn.calculateGeometry( rect );
			btn.x = c.x;
			btn.y = c.y;

			c.x += (btn.w + 10.0);
		}

		// position the right-floating buttons
		c = new Point((x + w - padding), (y + h - bdfb - padding));
		for (btn in r) {
			btn.calculateGeometry( rect );

			c.x -= (btn.w + 5);

			btn.x = c.x;
			btn.y = c.y;
		}
	}

	/**
	  * get the background-color for the controls widget
	  */
	private function getBackgroundColor():Color {
		if (cidm.exists('bg')) {
			return player.theme.restore(cidm['bg']);
		}
		else {
			var color = player.theme.primary.lighten( 12 );
			cidm['bg'] = player.theme.save( color );
			return color;
		}
	}

/* === Computed Instance Fields === */

	private var player(get, never):Player;
	private inline function get_player():Player return playerView.player;

/* === Instance Fields === */

	public var playerView : PlayerView;
	public var buttons : Array<PlayerControlButton>;
	public var seekBar : SeekBar;

	public var hovered : Bool = false;
	public var uiEnabled : Bool;
	public var uiHideDelay : Float;

	private var cidm : Map<String, Int>;
}
