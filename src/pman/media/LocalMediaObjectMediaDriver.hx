package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;

import pman.display.*;
import pman.media.PlaybackCommand;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * base-class for all media controllers that make use of a MediaObject
  */
@:allow( pman.display.media.LocalMediaObjectRenderer )
class LocalMediaObjectMediaDriver <T : MediaObject> extends MediaDriver {
	/* Constructor Function */
	public function new(media : T):Void {
		super();

		mediaObject = media;
	}

/* === Instance Fields === */

	override function play():Void m.play();
	override function pause():Void m.pause();
	override function togglePlayback():Void (m.paused?play:pause)();
	override function stop():Void {
		m.destroy();
	}
	override function getSource():String return m.src;
	override function getDurationTime():Float return m.durationTime;
	//override function getDuration():Duration return m.duration;
	override function getCurrentTime():Float return m.currentTime;
	override function getPlaybackRate():Float return m.playbackRate;
	override function getPaused():Bool return m.paused;
	override function getMuted():Bool return m.muted;
	override function getVolume():Float return m.volume;
	override function getEnded():Bool return m.ended;
	override function setSource(v:String):Void m.src = v;
	override function setCurrentTime(v:Float):Void m.currentTime = v;
	override function setPlaybackRate(v:Float):Void m.playbackRate = v;
	override function setVolume(v:Float):Void m.volume = v;
	override function setMuted(v:Bool):Void m.muted = v;

	override function getLoadSignal():VoidSignal return m.onload;
	override function getEndedSignal():VoidSignal return m.onended;
	override function getCanPlaySignal():VoidSignal return m.oncanplay;
	override function getPlaySignal():VoidSignal return m.onplay;
	override function getPauseSignal():VoidSignal return m.onpause;
	override function getLoadedMetadataSignal():VoidSignal return m.onloadedmetadata;
	override function getErrorSignal():Signal<Dynamic> return untyped m.onerror;
	override function getProgressSignal():Signal<Percent> return m.onprogress;
	override function getDurationChangeSignal():Signal<Delta<Duration>> return m.ondurationchange;
	override function getVolumeChangeSignal():Signal<Delta<Float>> return m.onvolumechange;
	override function getRateChangeSignal():Signal<Delta<Float>> return m.onratechange;

	// dispose of [this]'s memory allocations
	override function dispose():Void {
		// dump the mediaObject
		mediaObject.destroy();
	}

	override function hasMediaObject():Bool return true;
	override function getMediaObject():Null<MediaObject> return mediaObject;

/* === Computed Instance Fields === */

	private var m(get, never):T;
	private inline function get_m():T return mediaObject;

/* === Instance Fields === */

	private var mediaObject : T;
}
