package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;
import tannus.geom2.*;

import pman.core.*;
import pman.media.*;

//import js.html.Image in Img;
import gryffin.display.Canvas;
import gryffin.display.Image in Img;
import gryffin.display.Video;
import foundation.Image in FImage;

import gryffin.Tools.*;
import foundation.Tools.*;
import Math.*;
import tannus.math.TMath.*;
import tannus.math.Random;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class RawSingleThumbnailLoader extends StandardTask<String, Canvas> {
	/* Constructor Function */
	public function new(t : Track):Void {
		super();

		track = t;
		status = 'Preparing Task..';
	}

/* === Instance Methods === */

	/**
	  * Load the Thumbnail, and return a Promise
	  */
	public function loadThumbnail(getTime:Int->Int, mutateRect:Rect<Int>->Rect<Int>):Promise<Canvas> {
		this.getTime = getTime;
		this.mutateRect = mutateRect;

		return Promise.create({
			perform(function() {
				video.clear();
				return result;
			});
		});
	}

	/**
	  * Actual Action
	  */
	override private function action(done : Void->Void):Void {
		// validate [track]
		if (track.driver == null || !track.driver.hasMediaObject() || track.driver.getMediaObject() == null) {
			throw 'Error: Cannot load thumbnail from $track';
		}

		var stack = new AsyncStack();

		stack.push( load_video );
		stack.push( seek_video );
		stack.push( capture_video );

		stack.run(function() {
			done();
		});
	}

	/**
	  * Load the Video into memory
	  */
	private function load_video(done : Void->Void):Void {
		var mo = track.driver.getMediaObject();
		var source:String = mo.src;
		video = new Video();
		video.load(source, function() {
			var vr:Rect<Int> = new Rect(0, 0, video.naturalWidth, video.naturalHeight);
			dimensions = mutateRect( vr );
			time = getTime( video.duration.totalSeconds );

			done();
		});
	}

	/**
	  * Seek the video to the desired time
	  */
	private function seek_video(done : Void->Void):Void {
		video.seek(time, function() {
			defer( done );
		});
	}

	/**
	  * Capture the video
	  */
	private function capture_video(done : Void->Void):Void {
		var w:Int;
		var h:Int;

		if (dimensions == null) {
			w = video.naturalWidth;
			h = video.naturalHeight;
		}
		else {
			w = dimensions.w;
			h = dimensions.h;
		}

		canvas = Canvas.create(w, h);
		canvas.context.drawComponent(video, 0, 0, video.naturalWidth, video.naturalHeight, 0, 0, w, h);

		result = canvas;
		done();
	}

/* === Instance Fields === */

	public var track : Track;
	
	private var time : Int;
	private var dimensions : Rect<Int>;
	private var video : Video;
	private var canvas : Canvas;
	private var mutateRect : Rect<Int>->Rect<Int>;
	private var getTime : Int->Int;
}
