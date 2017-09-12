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

class PlaybackSpeedButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = true;
		name = 'playback-speed';

		widget = new PlaybackSpeedWidget(controls, this);
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	override function init(stage : Stage):Void {
		super.init( stage );

		controls.addSibling( widget );
	}

	override function update(stage : Stage):Void {
		super.update( stage );

		var ispeed:Int = round(player.playbackRate * 100);
		label = '$ispeed%';
	}

	// set up the icon data
	override function initIcon():Void {
		_il = [Icons.clockIcon(iconSize, iconSize).toImage()];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
		widget.toggleHidden();
	}

/* === Instance Fields === */

	public var widget : PlaybackSpeedWidget;
}
