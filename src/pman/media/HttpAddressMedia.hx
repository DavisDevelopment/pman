package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.File;
import tannus.sys.Path;
import tannus.sys.Mime;
import tannus.http.WebRequest;

import gryffin.media.MediaObject;
import gryffin.display.Video;
import gryffin.audio.Audio;

import pman.display.*;
import pman.display.media.*;

import foundation.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class HttpAddressMedia extends Media {
	/* Constructor Function */
	public function new(url : String):Void {
		super();

		src = MediaSource.MSUrl( url );
		this.url = url;

		determineMimeType();
	}

/* === Instance Methods === */

	override function getPlaybackDriver():Promise<PlaybackDriver> {
		return Promise.create({
			onReady(function() {
				if (mediaMime.type == 'video') {
					return cast new LocalVideoPlaybackDriver(buildVideoObject());
				}
				else {
					throw MediaError.EInvalidFormat;
				}
			});
		});
	}

	override function getRenderer(controller : PlaybackDriver):Promise<MediaRenderer> {
		return Promise.create({
			onReady(function() {
				return cast new LocalVideoRenderer(this, controller);
			});
		});
	}

	/**
	  * Build a video object from [url]
	  */
	private function buildVideoObject():Video {
		var video = new Video();
		video.load( url );
		return video;
	}

	private function determineMimeType():Void {
		var r = new WebRequest();
		r.open('HEAD', url);
		r.load(function() {
			var all = r.getAllResponseHeaders();
			mediaMime = new Mime(all['content-type'].before( ';' ));
			trace( mediaMime );
			declareReady();
		});
		r.send();
	}

/* === Instance Fields === */

	public var url : String;
	public var mediaMime : Null<Mime>;
}
