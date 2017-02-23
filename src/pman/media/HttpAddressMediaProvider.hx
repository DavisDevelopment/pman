package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.File;
import tannus.sys.Path;
import tannus.http.Url;

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

class HttpAddressMediaProvider extends MediaProvider {
	/* Constructor Function */
	public function new(url : String):Void {
		super();

		src = MediaSource.MSUrl( url );
		this.url = url;
	}

/* === Instance Methods === */

	/**
	  * obtain the media object
	  */
	override function getMedia():Promise<Media> {
		return Promise.create({
			defer(function() {
				var media:Media = cast new HttpAddressMedia( url );
				media.provider = this;
				return media;
			});
		});
	}

/* === Instance Fields === */

	public var url : String;
}
