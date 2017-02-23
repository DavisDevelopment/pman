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
import gryffin.audio.Audio;

import pman.display.*;
import pman.media.PlaybackCommand;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class LocalAudioPlaybackDriver extends LocalMediaObjectPlaybackDriver<Audio> {
	/* Constructor Function */
	public function new(audio : Audio):Void {
		super(cast audio);
	}

/* === Computed Instance Fields === */

	public var audio(get, never):Audio;
	private inline function get_audio():Audio return cast(m, Audio);
}
