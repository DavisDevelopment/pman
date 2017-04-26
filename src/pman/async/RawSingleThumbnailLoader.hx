package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;
import tannus.geom2.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

//import js.html.Image in Img;
import gryffin.display.Canvas;
import gryffin.display.Image in Img;
import gryffin.display.Video;
import foundation.Image in FImage;

import electron.ext.App;
import electron.ext.ExtApp;

import gryffin.Tools.*;
import foundation.Tools.*;
import Math.*;
import tannus.math.TMath.*;
import tannus.math.Random;
import tannus.TSys.systemName;

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

        // can use ffmpeg to load thumbnails
        return Promise.create({
            perform(function() {
                if (video != null)
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

		var sysname = systemName();
		(switch ( sysname ) {
            case 'Linux', 'Win32': loadWithFfmpeg;
            default: loadWithVideo;
		})( done );
	}

	/**
	  * load using ffmpeg
	  */
	private function loadWithFfmpeg(done : Void->Void):Void {
        if (systemName() == 'Win32') {
            var toolPath = track.player.app.appDir.appPath('assets/ffmpeg-static');
            ffmpeg.FFfmpeg.setFfmpegPath(toolPath.plusString('ffmpeg.exe'));
            ffmpeg.FFfmpeg.setFfprobePath(toolPath.plusString('ffprobe.exe'));
        }

        var mo:Video = cast track.driver.getMediaObject();
        var vr:Rect<Int> = new Rect(0, 0, mo.naturalWidth, mo.naturalHeight);
        var tr = mutateRect( vr );

        thumbProbe(getTime( mo.duration.totalSeconds ), '${tr.width}x${tr.height}', function(can : Canvas) {
            result = canvas = can;
            done();
        });
	}

	/**
	  * load using video
	  */
	private function loadWithVideo(done : Void->Void):Void {
        var stack = new AsyncStack();

		stack.push( load_video );
		stack.push( seek_video );
		stack.push( capture_video );

		stack.run(function() {
			done();
		});
	}

	/**
	  * obtain a thumbnail from the Track via ffmpeg
	  */
    private function thumbProbe(time:Float, size:String, callback:Canvas->Void):Void {
        if (!track.type.equals( MTVideo ))
            return ;
        var thumbPath:Path = App.getPath(ExtAppNamedPath.UserData).plusString( '_thumbs' );
        var m = new ffmpeg.FFfmpeg(track.getFsPath().toString());
        var paths:Array<Path> = [];
        m.onFileNames(function(filenames) {
            paths = filenames.map.fn(thumbPath.plusString(_));
        });
        m.onEnd(function() {
            var uri:String = ('file://${paths[0]}');
            Img.load(uri, function( img ) {
                img.ready.once(function() {
                    trace('IMAGE READY MOTHERFUCKER');
                    defer(function() {
                        var canvas = img.toCanvas();
                        @:privateAccess img.img.remove();
                        FileSystem.deleteFile( paths[0] );
                        callback( canvas );
                    });
                });
            });
        });
        m.screenshots({
            folder: thumbPath.toString(),
            filename: '%s|%r|%f.png',
            size: size,
            timemarks: [time]
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
