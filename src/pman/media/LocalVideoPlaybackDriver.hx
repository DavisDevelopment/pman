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
import gryffin.display.Video;

import pman.display.*;
import pman.media.PlaybackCommand;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class LocalVideoPlaybackDriver extends LocalMediaObjectPlaybackDriver<Video> {
	/* Constructor Function */
	public function new(video : Video):Void {
		super(cast video);
	}

/* === Computed Instance Fields === */

	public var video(get, never):Video;
	private inline function get_video():Video return cast(m, Video);
}
