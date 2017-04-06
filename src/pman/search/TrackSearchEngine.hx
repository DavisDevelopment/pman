package pman.search;

import pman.media.*;
import pman.media.MediaSource;

class TrackSearchEngine extends SearchEngine<Track> {
	override function getValue(track : Track):String {
		return track.title;
	}
	override function getValues(track : Track):Array<String> {
	    var values = [track.title];
	    switch ( track.source ) {
            case MSLocalPath( path ):
                values.push(path.toString());
            case MSUrl( url ):
                values.push( url );
	    }
	    return values;
	}
}
