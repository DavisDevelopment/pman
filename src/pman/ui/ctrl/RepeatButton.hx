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
        name = 'cycle-repeat';
	}

	

/* === Instance Methods === */

    /**
      * update [this] Button's label
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        switch ( player.repeat ) {
            case RepeatOff:
                label = '';

            case RepeatOnce:
                label ='Once';

            case RepeatIndefinite:
                label = 'On';

            case RepeatPlaylist:
                label = 'All';
        }

        enabled = (player.track == null || !player.track.type.equals(MTImage));
    }

	// set up icon info
	override function initIcon():Void {
		_il = [
			//Icons.repeatIcon(iconSize, iconSize, _fill(player.theme.primary.mix('#FFF', 0.5))).toImage(),
			Icons.repeatIcon(iconSize, iconSize).toImage(),
		    Icons.repeatIcon(iconSize, iconSize, _enabled()).toImage()
		];
	}

	// get the active icon at any given time
	override function getIcon():Null<Image> {
		return _il[(player.repeat == RepeatOff ? 0 : 1)];
	}
	
	// handle click events
	override function click(event : MouseEvent):Void {
		var repeatTypes: Array<RepeatType> = [RepeatOff, RepeatIndefinite, RepeatOnce, RepeatPlaylist];
        player.repeat = repeatTypes[(repeatTypes.indexOf(player.repeat) != repeatTypes.length - 1) ? repeatTypes.indexOf(player.repeat) + 1 : 0];
        //trace("Repeat mode is now: " + player.repeat);
	}
}
