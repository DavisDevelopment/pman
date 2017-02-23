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
import pman.ui.ctrl.PlayerControlButton;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * button used for toggling fullscreen
  */
class FullscreenButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = Right;
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
		//_il = [Assets.loadIcon('expand.png'), Assets.loadIcon('collapse.png')];
		_il = [Icons.expandIcon(iconSize, iconSize).toImage(), Icons.collapseIcon(iconSize, iconSize).toImage()];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[player.isFullscreen() ? 1 : 0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
		player.setFullscreen(!player.isFullscreen());
	}
}
