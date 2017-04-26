package pman.tools.chromecast;

import tannus.node.*;

import tannus.io.Getter;
import tannus.ds.*;

import pman.async.*;

import haxe.extern.EitherType;

import pman.tools.chromecast.ExtDevice;

class Device {
	/* Constructor Function */
	@:allow( pman.tools.chromecast.Browser )
	private function new(device : ExtDevice):Void {
		d = device;

		//__init();
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	private function __init():Void {
		var self:Obj = this;
		self.defineGetter('host', Getter.create( host ));
		self.defineGetter('name', Getter.create( name ));
	}

	/**
	  * initiate playback of some media
	  */
	public function play(media:EitherType<String, MediaDef>, seconds:Float, callback:VoidCb):Void {
		d.play(media, seconds, callback);
	}

	/**
	  * query the device for it's current status
	  */
	public function getStatus(callback : Cb<DeviceStatus>):Void {
		d.getStatus( callback );
	}

	/**
	  * seek to the given time
	  */
	public function seekTo(newCurrentTime:Float, callback:VoidCb):Void {
		d.seekTo(newCurrentTime, callback);
	}

	/**
	  * seek to the given time
	  */
	public function seek(time:Float, callback:VoidCb):Void {
		d.seek(time, callback);
	}

	/**
	  * pause the current media
	  */
	public function pause(f : VoidCb):Void {
		d.pause( f );
	}

	/**
	  * unpause the current media
	  */
	public function unpause(f : VoidCb):Void {
		d.unpause( f );
	}

	/**
	  * set the volume
	  */
	public function setVolume(volume:Float, cb:VoidCb):Void {
		d.setVolume(volume, cb);
	}

	/**
	  * stop the current media
	  */
	public function stop(cb : VoidCb):Void {
		d.stop( cb );
	}

	/**
	  * mute/unmute the current media
	  */
	public function setVolumeMuted(muted:Bool, cb:VoidCb):Void {
		d.setVolumeMuted(muted, cb);
	}

	/**
	  * close connection to [this] device
	  */
	public function close(cb : VoidCb):Void {
		d.close( cb );
	}

/* === Computed Instance Fields === */

	public var host(get, never):String;
	private inline function get_host():String return d.host;

	public var name(get, never):String;
	private inline function get_name():String return d.config.name;

/* === Instance Fields === */

	private var d : ExtDevice;
}
