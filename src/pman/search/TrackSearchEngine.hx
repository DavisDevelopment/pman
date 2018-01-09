package pman.search;

import pman.media.*;
import pman.media.info.*;
import pman.media.info.Mark;
import pman.media.MediaSource;

using Slambda;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

class TrackSearchEngine extends SearchEngine<Track> {
	override function getValue(track : Track):String {
		return track.title;
	}

	/**
	  * get values for given Track
	  */
	override function getValues(track : Track):Array<String> {
	    // create value list
	    var values:Array<String> = new Array();
	    inline function add(x)
	        values.push( x );
	    inline function nadd(x:Null<String>)
	        if (x.hasContent())
	            add( x );
	    inline function adds(x: Iterable<String>)
	        x.iter.fn(add(_));

	    // add track title
	    add( track.title );

	    // add track source
	    switch ( track.source ) {
	        // local file system path
            case MSLocalPath( path ):
                add(path.toString());
            // uri
            case MSUrl( url ):
                add( url );
	    }

	    // add values from track's metadata
	    if (track.data != null) {
	        // add mark names
	        for (m in track.data.marks) {
	            // if [m] is a named Mark
	            switch ( m.type ) {
                    case MarkType.Named( markName ):
                        // mark name
                        add( markName );

                    default:
                        continue;
	            }
	        }

	        // add tag names
	        for (t in track.data.tags) {
	            // add tag name
	            add( t.name );
	        }

	        // add actor names
	        for (a in track.data.actors) {
	            add( a.name );
	        }

	        nadd( track.data.description );
	        nadd( track.data.channel );
	    }
	    
	    return values;
	}
}
