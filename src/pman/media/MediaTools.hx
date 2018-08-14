package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import gryffin.media.MediaObject;
import gryffin.display.*;
import gryffin.audio.Audio;

import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

import electron.ext.NativeImage;

import pman.core.PlayerMediaContext;
import pman.display.*;
import pman.display.media.*;
import pman.ds.*;
import pman.bg.media.MediaType;
import pman.bg.media.MediaSource;
import pman.async.*;
import pman.async.tasks.*;
import pman.async.tasks.TrackListDataLoader;
//import pman.bg.MediaTools;

import js.html.MediaElement as NativeMediaObject;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda; 
using pman.bg.MediaTools;

/**
  * mixin class containing utility methods pertaining to the pman.media.* objects
  */
@:expose('MediaTools')
class MediaTools {
    /**
      probe the given Directory for all openable files
     **/
    public static function getAllOpenableFiles(dir:Directory, done:Array<File>->Void):Void {
        var probe = new OpenableFileProbe();
        probe.setSources([dir]);
        probe.run( done );
    }

    /**
      probe many directories for all contained files that PMan can open
     **/
    public static function igetAllOpenableFiles(idir:Iterable<Directory>, done:Array<File>->Void):Void {
        var coll = new Array();
        function collect(d:Directory, next:Void->Void) {
            getAllOpenableFiles(d, function(files) {
                coll = coll.concat( files );
                next();
            });
        }
        var stack = new AsyncStack();
        for (dir in idir) {
            stack.push(collect.bind(dir, _));
        }
        stack.run(function() {
            done( coll );
        });
    }

    /**
      convert the given list of File instances into a list of Track instances
     **/
    public static inline function convertToTracks(files : Array<File>):Array<Track> {
        return (new FileListConverter().convert( files ).toArray());
    }

    /**
      initialize a list of Track instances all at once
     **/
    public static function initAll(tracks:Array<Track>, done:Void->Void):Void {
        var initter = new TrackListInitializer();
        initter.initAll(tracks, function(count : Int) {
            done();
        });
    }

    /*
    @:deprecated
    public static function loadDataForAll(tracks:Array<Track>, ?done:Cb<TLDLResult>):Void {
        var loader = new TrackListDataLoader();
        loader.load(tracks, done);
    }
    */

    /**
      get underlying media object from the given MediaObject
     **/
	@:access( gryffin.display.Video )
	@:access( gryffin.audio.Audio )
	public static function getUnderlyingMediaObject(mo : MediaObject):NativeMediaObject {
	    if (Std.is(mo, Video)) {
	        return cast(cast(mo, Video).vid, NativeMediaObject);
	    }
        else if (Std.is(mo, Audio)) {
            return cast(cast(mo, Audio).sound, NativeMediaObject);
        }
        else {
            throw 'Error: Unknown MediaObject type';
        }
	}

    /**
	  load the MediaMetadata attached to the given MediaSource
     **/
	public static function getMediaMetadata(src:MediaSource):Promise<Null<MediaMetadata>> {
	    return new Promise(function(yes, no) {
	        switch ( src ) {
                case MSLocalPath( path ):
                    yes(cast new LoadMediaMetadata( path ).getMetadata());

                default:
                    throw 'Error: Media metadata can only be loaded for media items located on the local filesystem';
	        }
	    });
	}

    /**
      * trim leading '//' from String
      */
	public static inline function stripSlashSlash(s : String):String return s.withoutLeadingSlashes();
}

/**
  mixins for Uri strings
 **/
class UriTools {
    //
    public static function toMediaProvider(uri: String):MediaProvider {
        return MediaSourceTools.toMediaProvider(uri.toMediaSource());
    }

    public static function toTrack(uri: String):Track {
        return new Track(toMediaProvider( uri ));
    }
}

class MediaSourceTools {
    /**
      * make an educated guess at the title of the media referred to by the given MediaSource
      */
    public static function getTitle(src: MediaSource):String {
	    switch ( src ) {
            case MSLocalPath( path ):
                return path.name;

            case MSUrl( url ):
                return url;
	    }
    }

	/**
	  * convert MediaSource to a MediaProvider
	  */
	public static function toMediaProvider(src: MediaSource):MediaProvider {
	    switch ( src ) {
            case MSLocalPath( path ):
                return cast new LocalFileMediaProvider(new File( path ));

            case MSUrl( url ):
                var protocol:String = url.protocol().toLowerCase();
                switch ( protocol ) {
                    case 'http', 'https':
                        return cast new HttpAddressMediaProvider( url );

                    default:
                        throw 'Error: Unsupported URL "$url"';
                }
	    }
	}

	/**
	  * convert a MediaSource to a Track
	  */
	public static function toTrack(src: MediaSource):Track {
	    return new Track(toMediaProvider( src ));
	}
}

typedef URIMixin = pman.bg.URITools;
typedef URIMixin2 = pman.bg.MediaTools.UriTools;
typedef PathMixin = pman.bg.PathTools;
typedef MediaMixin = pman.bg.MediaTools;
typedef MediaRowMixin = pman.bg.MediaTools.MediaRowTools;
typedef MediaSourceMixin = pman.bg.MediaTools.MediaSourceTools;
