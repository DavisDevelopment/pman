package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.math.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;

import pman.core.*;
import pman.display.*;
import pman.bg.media.Dimensions;
import pman.bg.media.MediaFeature;
import pman.media.PlaybackCommand;
import pman.Errors.*; 

import edis.Globals.*;
import pman.Globals.*;

import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;

/**
  * class that receives playback commands and executes them
  */
class MediaDriver {
	/* Constructor Function */
	public function new():Void {
	    features = new Dict();
	}

/* === Instance Methods === */

	/**
	  * attach [this] to a Player
	  */
	public function attach(player:Player, done:VoidCb):Void {
		this.player = player;

		done();
	}

	/**
	  * execute the given command
	  */
	public function execute(cmd : PlaybackCommand):Void {
		switch ( cmd ) {
			case PCPlay:
				play();

			case PCPause:
				pause();

			case PCTogglePlayback:
				togglePlayback();

			case PCStop:
				stop();

			case PCTime(time, rel):
				if (rel == null || !rel) {
					setCurrentTime( time );
				}
				else {
					setCurrentTime(getCurrentTime() + time);
				}

			case PCSpeed(speed, rel):
				if (rel == null || !rel) {
					setPlaybackRate( speed );
				}
				else {
					setPlaybackRate(getPlaybackRate() + speed);
				}

			case PCVolume(volume, rel):
				if (rel == null || !rel) {
					setVolume( volume );
				}
				else {
					setVolume(getVolume() + volume);
				}
		}
	}

	/**
	  * deallocate fields and memory used by [this] object
	  */
	public function dispose(cb: VoidCb):Void {
		return cb();
	}

	/**
	  * Determine whether [this] driver utilizes a MediaObject of any kind
	  */
	public function hasMediaObject():Bool {
		return false;
	}

	/**
	  * Request the MediaObject used by [this] driver (if any)
	  */
	public function getMediaObject():Null<MediaObject> {
		return null;
	}

/* === Playback Methods === */

	public function play():Void ni();
	public function pause():Void ni();
	public function stop():Void ni();
	public function togglePlayback():Void ni();

/* === Property Methods === */

	public function getSource():String ni();
	public function getDuration():Duration {
		return tannus.media.Duration.fromFloat(getDurationTime());
	}
	public function getDurationTime():Float ni();
	public function getCurrentTime():Float ni();
	public function getPlaybackRate():Float ni();
	public function getPaused():Bool ni();
	public function getMuted():Bool ni();
	public function getEnded():Bool ni();
	public function getVolume():Float ni();
	public function getNaturalDimensions():Dimensions ni();
	public function getDimensions():Dimensions ni();

	public function setSource(src : String):Void ni();
	public function setCurrentTime(time : Float):Void ni();
	public function setPlaybackRate(rate : Float):Void ni();
	public function setVolume(vol : Float):Void ni();
	public function setMuted(v : Bool):Void ni();
	
/* === Event Methods === */

	public function getLoadSignal():VoidSignal ni();
	public function getEndedSignal():VoidSignal ni();
	public function getCanPlaySignal():VoidSignal ni();
	public function getPlaySignal():VoidSignal ni();
	public function getPauseSignal():VoidSignal ni();
	public function getLoadedMetadataSignal():VoidSignal ni();
	public function getErrorSignal():Signal<Dynamic> ni();
	public function getProgressSignal():Signal<Percent> ni();
	public function getDurationChangeSignal():Signal<Delta<Duration>> ni();
	public function getVolumeChangeSignal():Signal<Delta<Float>> ni();
	public function getRateChangeSignal():Signal<Delta<Float>> ni();

/* === Instance Fields === */

	public var player : Null<Player>;
	public var features : Dict<MediaFeature, Bool>;
}
