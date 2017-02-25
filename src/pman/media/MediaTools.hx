package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.File;
import tannus.sys.Path;

import gryffin.media.MediaObject;
import gryffin.display.Video;
import gryffin.audio.Audio;

import Slambda.fn;
import foundation.Tools.defer;

import pman.core.PlayerMediaContext;
import pman.display.*;
import pman.display.media.*;

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
	  * parse the given URI to a MediaProvider
	  */
	public static function uriToMediaProvider(uri : String):MediaProvider {
	    if (uri.startsWith('/')) {
	        return cast new LocalFileMediaProvider(new File( uri ));
	    }
        else {
            var protocol:String = uri.before(':');
            switch ( protocol ) {
                case 'file':
                    return cast new LocalFileMediaProvider(new File(new Path(stripSlashSlash(uri.after(':')))));

                case 'http', 'https':
                    return cast new HttpAddressMediaProvider( uri );

                default:
                    throw 'Error: Malformed media URI "$uri"';
            }
        }
	}

	public static inline function parseToTrack(uri : String):Track {
	    return new Track(uriToMediaProvider( uri ));
	}

	private static function stripSlashSlash(s : String):String {
	    if (s.startsWith('//')) {
	        s = s.slice( 2 );
	    }
	    return s;
	}
}
