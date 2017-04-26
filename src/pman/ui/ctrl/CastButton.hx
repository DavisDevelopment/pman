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
import pman.async.*;

import pman.tools.chromecast.*;
import pman.tools.localip.LocalIp.get as localip;

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
		//enabled = false;
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
	    castDevice(function(?err, ?device) {
	        if (err != null)
	            throw err;

	        getUrl(function(?err, ?address) {
	            if (err != null)
	                throw err;
	            device.play(address, 0, function(?error) {
	                if (error != null)
	                    throw error;
	                device.getStatus(function(?err, ?status) {
	                    if (err != null) throw err;
	                    trace( status );
	                });
	            });
	        });
	    });
	}

    /**
      * obtain a casting device
      */
	private function castDevice(done : Cb<Device>):Void {
	    if (device != null) {
	        return done(null, device);
	    }
        else {
            var browser = new Browser();
            browser.onDevice(function(d : Device) {
                if (d.name.htmlUnescape() == 'Ryans Room') {
                    this.device = d;
                    browser.destroy();
                    done(null, device);
                }
            });
            browser.update();
        }
	}

    /**
      * obtain a url to the media to be casted
      */
	private function getUrl(done : Cb<String>):Void {
	    var uuid = player.httpRouteTo( player.track );
	    localip('wlo1', function(?error, ?ipAddress) {
	        if (error != null)
	            done(error, null);
            else {
                var url:String = 'http://$ipAddress:6969/watch/$uuid';
                done(null, url);
            }
	    });
	}

	/**
	  * get device status on a loop
	  */
	private function statusLoop(device : Device):Void {
	    function gs(?error, ?status:DeviceStatus) {
	        trace( status );

	        device.getStatus( gs );
	    }
	    device.getStatus( gs );
	}

	/**
	  * update [this] Button
	  */
	override function update(stage : Stage):Void {
	    super.update( stage );
	}

/* === Instance Fields === */

	private var device : Null<Device> = null;
}
