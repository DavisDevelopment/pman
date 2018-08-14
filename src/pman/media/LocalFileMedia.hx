package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.File;
import tannus.sys.Path;
import tannus.async.*;

import gryffin.media.MediaObject;
import gryffin.display.Video;
import gryffin.display.Image;
import gryffin.audio.Audio;

import pman.display.*;
import pman.display.media.*;
import pman.bg.media.MediaType;
import pman.bg.media.MediaSource;

import electron.ext.FileFilter;

//import foundation.Tools.defer;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.bg.DictTools;
using tannus.async.Asyncs;

class LocalFileMedia extends Media {
	/* Constructor Function */
	public function new(file : File):Void {
		super();
		
		src = MediaSource.MSLocalPath( file.path );
		this.file = file;

		declareReady();
	}

/* === Instance Methods === */

	/**
	  * deallocate memory
	  */
	override function dispose(cb: VoidCb):Void {
		super.dispose(cb.wrap(function(_, ?err) {
            file = null;

            _( err );
		}));
	}

	/**
	  * create the playback driver
	  */
	override function getDriver():Promise<MediaDriver> {
		return Promise.create({
			onReady(function() {
			    var driver:Null<MediaDriver> = null;
				// video files
				if (isVideoFile()) {
					driver = cast new LocalVideoMediaDriver(buildVideoObject());
				}
				// audio files
				else if (isAudioFile()) {
					driver = cast new LocalAudioMediaDriver(buildAudioObject());
				}
				// image files
                else if (isImageFile()) {
                    driver = cast new LocalImageMediaDriver(buildImage());
                }
				// unsupported files
				else {
					throw MediaError.EInvalidFormat;
				}

				if (driver != null) {
				    driver.features = cast features.copy();
				    return driver;
				}
			});
		});
	}

	/**
	  * create the renderer
	  */
	override function getRenderer(controller : MediaDriver):Promise<MediaRenderer> {
		return Promise.create({
			onReady(function() {
				// video files
				if (isVideoFile()) {
					return cast new LocalVideoRenderer(this, controller);
				}
				// audio files
				else if (isAudioFile()) {
					return cast new LocalAudioRenderer(this, controller);
				}
				// image files
                else if (isImageFile()) {
                    return cast new LocalImageRenderer(this, controller);
                }
				// unsupported files
				else {
					throw MediaError.EInvalidFormat;
				}
			});
		});
	}

	/**
	  * construct the Video Object
	  */
	private function buildVideoObject():Video {
		var video = new Video();
		initializeMediaObject(cast video);
		return video;
	}

	/**
	  * construct the Audio Object
	  */
	private function buildAudioObject():Audio {
		var audio = new Audio();
		initializeMediaObject(cast audio);
		return audio;
	}

	private function buildImage():Image {
	    var image = new Image();
	    image.src = 'file://${file.path}';
	    return image;
	}

	/**
	  * perform initialization tasks on MediaObject
	  */
	private function initializeMediaObject(media : MediaObject):Void {
		media.src = 'file://${file.path}';
	}

	/**
	  * check whether [this] refers to a video file
	  */
	private inline function isVideoFile():Bool {
	    return (type != null && type.equals(MTVideo));
	}

	/**
	  * check whether [this] refers to an audio file
	  */
	private inline function isAudioFile():Bool {
	    return (type != null && type.equals(MTAudio));
	}

	/**
	  * check whether [this] refers to an image file
	  */
	private inline function isImageFile():Bool {
	    return (type != null && type.equals(MTImage));
	}

/* === Computed Instance Fields === */

	private var extensionName(get, never):String;
	private inline function get_extensionName():String return file.path.extension;

/* === Instance Fields === */

	private var file : File;
}
