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

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
import pman.core.PlayerPlaybackProperties;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * button used for toggling playback
  */
class RepeatButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

        btnFloat = false;
	}

	override function update(stage : Stage):Void {
		super.update( stage );

		var repeatMode:RepeatType = player.repeat;
		switch (repeatMode) {
			case RepeatOff:
				label = 'Off';
			case RepeatOnce:
				label ='Once';
			case RepeatIndefinite:
				label = 'On';
			case RepeatPlaylist:
				label = 'All';
			default:
				label = 'HOW EVEN?!';
		}
	}

/* === Instance Methods === */

	// set up icon info
	override function initIcon():Void {
		_il = [Icons.repeatIcon(iconSize, iconSize).toImage()];
	}

	// get the active icon at any given time
	override function getIcon():Null<Image> {
		return _il[0];
	}
	
	// handle click events
	override function click(event : MouseEvent):Void {
		var repeatTypes: Array<RepeatType> = [RepeatOff, RepeatIndefinite, RepeatOnce, RepeatPlaylist];
        player.repeat = repeatTypes[(repeatTypes.indexOf(player.repeat) != repeatTypes.length - 1) ? repeatTypes.indexOf(player.repeat) + 1 : 0];
        trace("Repeat mode is now: " + player.repeat);
	}
}
