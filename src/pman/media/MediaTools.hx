package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import gryffin.media.MediaObject;
import gryffin.display.*;
import gryffin.audio.Audio;

import Slambda.fn;
import foundation.Tools.defer;

import electron.ext.NativeImage;

import pman.core.PlayerMediaContext;
import pman.display.*;
import pman.display.media.*;
import pman.ds.*;
import pman.media.MediaType;
import pman.media.MediaSource;
import pman.async.*;
import pman.async.tasks.*;
import pman.async.tasks.TrackListDataLoader;

import js.html.MediaElement as NativeMediaObject;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda; 

/**
  * mixin class containing utility methods pertaining to the pman.media.* objects
  */
class MediaTools {
    /**
      * probe the given Directory for all openable files
      */
    public static function getAllOpenableFiles(dir:Directory, done:Array<File>->Void):Void {
        var probe = new OpenableFileProbe();
        probe.setSources([dir]);
        probe.run( done );
    }
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
      * convert the given file list into a track list
      */
    public static inline function convertToTracks(files : Array<File>):Array<Track> {
        return (new FileListConverter().convert( files ).toArray());
    }

    /**
      * initialize a list of Tracks all at once
      */
    public static function initAll(tracks:Array<Track>, done:Void->Void):Void {
        var initter = new TrackListInitializer();
        initter.initAll(tracks, function(count : Int) {
            done();
        });
    }

    /**
      * load data for a list of Tracks
      */
    public static function loadDataForAll(tracks:Array<Track>, ?done:Cb<TLDLResult>):Void {
        var loader = new TrackListDataLoader();
        loader.load(tracks, done);
    }

	/**
	  * given a Track object, loads the [media, driver, renderer] fields onto that Track
	  */
	@:access( pman.media.Track )
	public static function loadTrackMediaState(track:Track, callback:Null<Dynamic>->Void):Void {
		var rethrow = fn([error] => callback( error ));
		track.provider.getMedia().unless( rethrow ).then(function(media : Media) {
			track.media = media;
			media.getPlaybackDriver().unless( rethrow ).then(function(driver : PlaybackDriver) {
				track.driver = driver;
				media.getRenderer( driver ).unless( rethrow ).then(function(renderer : MediaRenderer) {
					track.renderer = renderer;
					callback( null );
				});
			});
		});
	}

	/**
	  * wraps a Promise in a standard js-style callback
	  */
	private static function jscbWrap<T>(promise:Promise<T>, handler:Null<Dynamic>->T->Void):Void {
		promise.then(fn([result] => handler(null, result)));
		promise.unless(fn([error] => handler(error, null)));
	}

	/**
	  * get underlying media object from the given MediaObject
	  */
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

	public static function mediaSourceToUri(src : MediaSource):String {
	    switch ( src ) {
            case MSLocalPath(_.toString() => path):
                return path;

            case MSUrl( url ):
                return url;
	    }
	}

	public static function mediaSourceName(src : MediaSource):String {
	    switch ( src ) {
            case MSLocalPath( path ):
                return path.name;

            case MSUrl( url ):
                return url;
	    }
	}

    /**
      * convert the given URI to a MediaSource
      */
	public static function uriToMediaSource(uri : String):MediaSource {
        var winPath:RegEx = new RegEx(~/^([A-Z]):\\/i);
        if (winPath.match( uri )) {
            return MSLocalPath(new Path( uri ));
        }
        else if (uri.startsWith('/')) {
	        return MSLocalPath(new Path( uri ));
	    }
        else {
            var protocol:String = uri.before(':');
            switch ( protocol ) {
                case 'file':
                    return MSLocalPath(new Path(stripSlashSlash(uri.after(':'))));

                case 'http', 'https':
                    return MSUrl( uri );

                default:
                    return MSLocalPath(new Path( uri ));
            }
        }
	}

	/**
	  * convert MediaSource to a MediaProvider
	  */
	public static function mediaSourceToMediaProvider(src : MediaSource):MediaProvider {
	    switch ( src ) {
            case MSLocalPath( path ):
                return cast new LocalFileMediaProvider(new File( path ));

            case MSUrl( url ):
                var protocol:String = url.before(':').toLowerCase();
                switch ( protocol ) {
                    case 'http', 'https':
                        return cast new HttpAddressMediaProvider( url );

                    default:
                        throw 'Error: Unsupported URL "$url"';
                }
	    }
	}

	/**
	  * parse the given URI to a MediaProvider
	  */
	public static function uriToMediaProvider(uri : String):MediaProvider {
	    return mediaSourceToMediaProvider(uriToMediaSource( uri ));
	}

    /**
      * parse the given URI into a Track object
      */
	public static inline function parseToTrack(uri : String):Track {
	    return new Track(uriToMediaProvider( uri ));
	}

	/**
	  * load the MediaMetadata attached to the given MediaSource
	  */
	public static function getMediaMetadata(src:MediaSource):Promise<Null<MediaMetadata>> {
	    return Promise.create({
	        switch ( src ) {
                case MSLocalPath( path ):
                    @forward new LoadMediaMetadata( path ).getMetadata();

                default:
                    throw 'Error: Media metadata can only be loaded for media items located on the local filesystem';
	        }
	    });
	}

    /**
      * get the metadata loader class associated with the mime type of the given path
      */
    /*
	private static function metadataLoaderClass(path : Path):Null<Class<MediaMetadataLoader>> {
	    switch (path.extension.toLowerCase()) {
            case 'mp3':
                return MP3MetadataLoader;
            case 'mp4':
                return MP4MetadataLoader;
            default:
                return null;
	    }
	}
	*/

    /**
      * trim leading '//' from String
      */
	public static function stripSlashSlash(s : String):String {
	    if (s.startsWith('//')) {
	        s = s.slice( 2 );
	    }
	    return s;
	}
}
