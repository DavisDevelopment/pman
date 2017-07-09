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
class TrackShowInfoButton extends TrackControlButton {
	/* Constructor Function */
	public function new(c : TrackControlsView):Void {
		super( c );

        iconSize = c.iconSize;
		btnFloat = Right;
		tooltip = 'Media Info';
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
	    _il = [
	        _iconus('infoIcon', iconSize)
	    ];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
	    return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
	    //TODO
	}
}
