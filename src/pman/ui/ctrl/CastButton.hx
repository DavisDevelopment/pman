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

import pman.tools.chromecast.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class CastButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = true;
		enabled = false;
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
		_il = [Icons.castIcon(iconSize, iconSize).toImage()];
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[0];
	}

	// handle click events
	override function click(event : MouseEvent):Void {
		if (browser == null) {
			browser = Browser.create();
			browser.deviceFound.on(function( device ) {
				var name:String = device.name.htmlUnescape();
				switch ( name ) {
					case 'Ryans Room':
						var m = {
							url: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4'
						};
						device.play(m, 0, function(err : Null<Dynamic>) {
							if (err != null) {
								trace( err );
							}
							else {
								trace( 'playback started' );
								device.pause(function(err) {
									device.getStatus(function(err, status) {
										trace( status );
										device.stop(function(err) {
											browser.destroy();
											browser = null;
										});
									});
								});
							}
						});

					default:
						null;
				}
			});
		}
		browser.update();
	}

/* === Instance Fields === */

	private var browser : Null<Browser> = null;
}
