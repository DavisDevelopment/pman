package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;
import tannus.geom2.*;

import pman.core.*;
import pman.media.*;
import pman.ui.ctrl.SeekBar;

//import js.html.Image in Img;
import gryffin.display.Canvas;
import gryffin.display.Image in Img;
import foundation.Image in FImage;
import gryffin.display.Video;

import gryffin.Tools.*;
import foundation.Tools.*;
import Math.*;
import tannus.math.TMath.*;
import tannus.math.Random;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

@:access( bplayer.core.Player )
@:access( bplayer.core.media.VideoMediaContext )
class SeekbarPreviewThumbnailLoader extends RawSingleThumbnailLoader {
	/* Constructor Function */
	public function new(track:Track, bar:SeekBar):Void {
		super( track );

		seekbar = bar;
	}

/* === Instance Methods === */

	/**
	  * Load a preview thumbnail
	  */
	public function loadPreview(time:Int, video:Video):Promise<Canvas> {
		// get reference to the Player
		var player:Player = seekbar.player;
		// get a reference to the video
		var height:Int = floor(0.2 * player.view.h);
		// calculate the full dimensions of the thumbnail
		var rect:Rect<Int> = new Rect(0, 0, video.naturalWidth, video.naturalHeight);
		rect = rect.scale(null, height).ceil();

		return loadThumbnail(fn([d] => time), fn([r] => rect));
	}

/* === Instance Fields === */

	private var seekbar : SeekBar;
}
