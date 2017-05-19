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
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * button used for toggling playback
  */
class PlaybackButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );
	}

/* === Instance Methods === */

	// set up icon info
	override function initIcon():Void {
		_il = [Icons.playIcon(iconSize, iconSize, function(p){p.style.fill = p.style.stroke;}).toImage(), Icons.pauseIcon(iconSize, iconSize, function(p){p.style.fill = p.style.stroke;}).toImage()];
	}

	// get the active icon at any given time
	override function getIcon():Null<Image> {
		return _il[player.paused ? 0 : 1];
	}
	
	// handle click events
	override function click(event : MouseEvent):Void {
		player.togglePlayback();
	}
}
