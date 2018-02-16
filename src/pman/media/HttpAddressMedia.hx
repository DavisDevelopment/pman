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

import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using pman.bg.DictTools;
using tannus.ds.MapTools;
using tannus.ds.AnonTools;

class HttpAddressMedia extends Media {
	/* Constructor Function */
	public function new(url : String):Void {
		super();

		src = MediaSource.MSUrl( url );
		this.url = url;

		//determineMimeType();
		process_url();
	}

/* === Instance Methods === */

	override function getDriver():Promise<MediaDriver> {
		return Promise.create({
			onReady(function() {
				if (mediaMime.type == 'video') {
					return cast new LocalVideoMediaDriver(buildVideoObject());
				}
				else {
					throw MediaError.EInvalidFormat;
				}
			});
		});
	}

	override function getRenderer(controller : MediaDriver):Promise<MediaRenderer> {
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
			trace(all.toObject());
			mediaMime = new Mime(all['content-type'].before( ';' ));
			trace( mediaMime );
			declareReady();
		});
		r.send();
	}

	private function process_url():Void {
	    var handler = new pman.http.UrlTransformer();
	    handler.transform( url ).then(function(new_url) {
	        this.url = new_url;
	        trace( url );
	        declareReady();
	    }).unless(function(error) {
	        report( error );
	    });
	}

/* === Instance Fields === */

	public var url : String;
	public var mediaMime : Null<Mime>;
}
