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
class TrackAddToPlaylistButton extends TrackControlButton {
	/* Constructor Function */
	public function new(c : TrackControlsView):Void {
		super( c );

        iconSize = c.iconSize;
		btnFloat = Right;
		tooltip = 'Add to Playlist';
		widget = new PlaylistChooserWidget( this );
	}

/* === Instance Methods === */

    override function init(stage : Stage):Void {
        super.init( stage );
        tcontrols.addSibling( widget );
        widget.hide();
    }

    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
    }

    override function update(stage:Stage):Void {
        super.update( stage );
    }

	// set up the icon data
	override function initIcon():Void {
	    _il = [
	        _icon(Icons.plusIcon, iconSize)
	    ];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
	    return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
	    if (widget._hidden) {
	        var prom = widget.open();
	    }
        else widget.hide();

	    if ( showWidget ) {
	        widget.refresh();
	    }
	}

    public var showWidget(get, never): Bool;
    private inline function get_showWidget() return !widget._hidden;

/* === Instance Fields === */

    public var widget : PlaylistChooserWidget;
}
