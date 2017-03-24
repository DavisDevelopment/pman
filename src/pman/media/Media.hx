package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.http.Url;

import gryffin.media.MediaObject;

import pman.display.*;
import pman.display.media.*;

import foundation.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * an Object that represents the data for a piece of playable Media,
  * and any data necessary to build the PlaybackDriver for said Media
  */
class Media {
	/* Constructor Function */
	public function new():Void {
		_ready = {
			value : false,
			signal : new VoidSignal()
		};
		_ready.signal.once(function() {
			_ready.value = true;
		});
	}

/* === Instance Methods === */

	/**
	  * get the name of [this] Media
	  */
	public function getName():String {
		return switch ( src ) {
			case MediaSource.MSLocalPath( path ): path.name;
			case MediaSource.MSUrl( url ): url;
		}
	}

	/**
	  * build the PlaybackDriver for [this] Media
	  */
	public function getPlaybackDriver():Promise<PlaybackDriver> {
		throw 'Not Implemented';
	}

	/**
	  * build the MediaView for [this] Media
	  */
	public function getRenderer(controller : PlaybackDriver):Promise<MediaRenderer> {
		throw 'Not Implemented';
	}

	/**
	  * disassemble data structures and deallocate memory
	  */
	public function dispose():Void {
		_ready.signal.clear();
		_ready = null;
		src = null;
		provider = null;
	}

	/**
	  * wait for [this] Media to be ready
	  */
	public function onReady(callback : Void->Void):Void {
		if (isReady()) {
			defer( callback );
		}
		else {
			_ready.signal.once(function() {
				defer( callback );
			});
		}
	}

	/**
	  * query readiness
	  */
	public inline function isReady():Bool {
		return _ready.value;
	}
	private inline function declareReady():Void {
		_ready.signal.fire();
	}

/* === Instance Fields === */

	public var src(default, null):MediaSource;
	public var type(default, null):MediaType;
	public var provider : MediaProvider;

	private var _ready : ReadyInfo;
}

private typedef ReadyInfo = {
	value : Bool,
	signal : VoidSignal
};
