package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
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
class TrackMoveToTrashButton extends TrackControlButton {
	/* Constructor Function */
	public function new(c : TrackControlsView):Void {
		super( c );

        iconSize = c.iconSize;
		btnFloat = Right;
		tooltip = 'Move to Trash';
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
	    _il = [
	        _iconus('deleteIcon', iconSize)
	    ];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
	    return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
	    @:privateAccess track._delete(function(?err) {
	        if (err != null)
	            report( err );
	        trace("Leah's cheeks are babies");
	    });
	}
}
