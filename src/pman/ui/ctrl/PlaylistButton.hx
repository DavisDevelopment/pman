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
class PlaylistButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = Right;
		name = 'toggle-playlist';
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
	    function active(path : vex.core.Path) {
	        path.style.fill = theme.secondary;
	        path.style.stroke = 'none';
	    }

	    _il = [
	        Icons.listIcon(iconSize, iconSize).toImage(),
	        Icons.listIcon(iconSize, iconSize, active).toImage()
	    ];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[player.isPlaylistOpen() ? 1 : 0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
        player.togglePlaylist();
	}
}
