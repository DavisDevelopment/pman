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
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * button used for skipping to the next track
  */
class PreviousButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = false;
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
		_il = [Icons.prevIcon(iconSize, iconSize).toImage()];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
		var nt = player.getPreviousTrack();
		if (nt != null) {
			player.openTrack( nt );
		}
	}

    // update tooltip
	override function update(stage : Stage):Void {
	    super.update( stage );
	    var t = player.getPreviousTrack();
	    if (t != null) {
	        tooltip = t.title;
	    }
        else tooltip = null;
    }
}
