package pman.ui.ctrl;

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
import pman.ui.*;
import pman.ui.ctrl.PlaybackSpeedWidget;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:access( pman.ui.ctrl.SeekBar )
class PlaybackSpeedOption extends Ent {
	/* Constructor Function */
	public function new(c:PlayerControlsView, b:PlaybackSpeedButton, w:PlaybackSpeedWidget, v:NamedSpeed):Void {
		super();

		controls = c;
		button = b;
		widget = w;
		value = v;

		tb = new TextBox();
		tb.fontSize = 10;
		tb.fontSizeUnit = 'pt';
		tb.color = new Color(255, 255, 255);
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	override function init(stage : Stage):Void {
		super.init( stage );

		on('click', onClick);
	}

	/**
	  * update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		var mp = stage.getMousePosition();
		var hovered:Bool = (mp != null && containsPoint( mp ));
		
		if ( hovered ) {
			tb.color = button.player.theme.secondary;
		}
		else {
			tb.color = new Color(255, 255, 255);
		}

		tb.text = value.getName();
	}

	/**
	  * render [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		c.beginPath();
		c.strokeStyle = controls.seekBar.getBackgroundColor().toString();
		c.drawRect( rect );
		c.closePath();
		c.stroke();

		var tbr = new Rectangle(0, 0, tb.width, tb.height);
		tbr.centerX = centerX;
		tbr.centerY = centerY;

		c.drawComponent(tb, 0, 0, tb.width, tb.height, tbr.x, tbr.y, tbr.w, tbr.h);
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		w = (tb.width + 2);
		h = (tb.height + 2);
		centerX = widget.centerX;
	}

	/**
	  * handle a Click event
	  */
	public function onClick(event : MouseEvent):Void {
		button.player.playbackRate = value.getValue();

		widget.toggleHidden();
	}

/* === Instance Fields === */

	// the value represented by [this] option
	public var value : NamedSpeed;
	
	// the TextBox used to display that value
	private var tb : TextBox;
	
	public var controls : PlayerControlsView;
	public var button : PlaybackSpeedButton;
	public var widget : PlaybackSpeedWidget;
}
