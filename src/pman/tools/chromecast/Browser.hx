package pman.tools.chromecast;

import tannus.node.*;

import tannus.io.*;
import tannus.ds.*;

import pman.tools.chromecast.ExtDevice;

class Browser {
	/* Constructor Function */
	private function new(browser : ExtBrowser):Void {
		b = browser;

		deviceFound = new Signal();

		__init();
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	private function __init():Void {
		// handle extDevice
		function device_on(extDevice : ExtDevice):Void {
			var device:Device = new Device( extDevice );
			deviceFound.call( device );
		}
		b.on('deviceOn', device_on);
	}

	/**
	  *  destroy [this] Browser
	  */
	public function destroy():Void {
		// de-initialize stuff
		b.destroy();

		// nullify fields and free up memory
		b = null;
	}

	/**
	  * update the device-list
	  */
	public function update():Void {
		b.update();
	}

/* === Instance Fields === */

	public var deviceFound : Signal<Device>;

	private var b : ExtBrowser;

/* === Class Methods === */

	/**
	  * create and return a new Browser
	  */
	public static inline function create():Browser {
		return new Browser(new ExtBrowser());
	}
}
