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
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * button used for toggling fullscreen
  */
class TrackStarredButton extends TrackControlButton {
	/* Constructor Function */
	public function new(c : TrackControlsView):Void {
		super( c );

        iconSize = c.iconSize;
		btnFloat = Right;
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
	    _il = [
	        Icons.starIcon(iconSize, iconSize, _outline('#FFF', 1.25)).toImage(),
	        Icons.starIcon(iconSize, iconSize, _fill(theme.secondary.lighten( 45.0 ))).toImage()
	    ];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
	    return _il[trackData.ternary((_.starred ? 1 : 0), 0)];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
        track.toggleStarred();
	}
}
