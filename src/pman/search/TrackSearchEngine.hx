package pman.search;

import pman.media.*;

class TrackSearchEngine extends SearchEngine<Track> {
	override function getValue(track : Track):String {
		return track.title;
	}
}
