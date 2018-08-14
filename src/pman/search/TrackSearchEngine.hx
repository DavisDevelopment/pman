package pman.search;

import pman.media.*;
import pman.media.info.*;
import pman.bg.media.Mark;
import pman.bg.media.MediaSource;

using Slambda;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

/**
  engine for searching Track instances
 **/
class TrackSearchEngine extends SearchEngine<Track> {
    /**
      get a singular value for a given Track
     **/
	override function getValue(track : Track):String {
		return (caseSensitive ? track.title : track.title.toLowerCase());
	}

	/**
	  * get values for given Track
	  */
	override function getValues(track : Track):Array<String> {
	    // create value list
	    var values:Array<String> = new Array();

	    // add [x] to [values]
	    inline function add(x)
	        values.push( x );

	    // add [x] to [values], handling case-sensitivity and value-trimming
	    inline function cadd(x: Dynamic) {
	        var s:String = Std.string( x ).trim();
	        if (!s.empty()) {
	            add(caseSensitive ? s : s.toLowerCase());
	        }
	    }

	    // add [x] to [values] if [x] is a non-null non-empty value
	    inline function nadd(x:Null<String>)
	        if (x.hasContent())
	            cadd( x );

	    // add every value in [x] to [values]
	    inline function adds(x: Iterable<String>) {
	        x.iter.fn(cadd(_));
        }

	    // add track title
	    cadd( track.title );

	    // add track source
	    switch track.source {
	        // local file system path
            case MSLocalPath( path ):
                cadd( path );

            // uri
            case MSUrl( url ):
                cadd( url );
	    }

	    // add values from track's metadata
	    if (track.data != null) {
	        // assign track-data to a variable
	        var data:TrackData = track.data;

            // if [marks] property is present
	        if (data.checkProperty('marks')) {
                // add mark names
                for (m in data.marks) {
                    // if [m] is a named Mark
                    switch ( m.type ) {
                        case MarkType.Named( markName ):
                            // mark name
                            cadd( markName );

                        default:
                            continue;
                    }
                }
            }

            // if [tags] property is present
            if (data.checkProperty('tags')) {
                // add tag names
                for (t in data.tags) {
                    // add tag name
                    cadd( t.name );
                }
            }

            if (data.checkProperty('actors')) {
                // add actor names
                for (a in data.actors) {
                    cadd( a.name );
                }
            }

            if (data.checkProperty('description'))
                nadd( track.data.description );

            if (data.checkProperty('channel'))
                nadd( track.data.channel );
	    }
	    
	    return values;
	}
}
