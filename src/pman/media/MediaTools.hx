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
	  * given a MediaProvider, load the Media, and PlaybackDriver associated with it
	  */
	public static function buildContextInfoFromProvider(provider : MediaProvider):Promise<MediaContextInfo> {
		//TODO actually catch and handle errors
		return Promise.create({
			var mediaPromise = provider.getMedia();
			mediaPromise.then(function(media : Media) {
				var driverPromise = media.getPlaybackDriver();
				driverPromise.then(function(driver : PlaybackDriver) {
					//return inf(provider, media, driver);
					media.getRenderer( driver )
						.then(function( renderer ) {
							return inf(provider, media, driver, renderer);
						})
						.unless(function( error ) {
							throw error;
						});
				});
				driverPromise.unless(function(error : Dynamic) {
					throw error;
				});
			});
			mediaPromise.unless(function(error : Dynamic) {
				throw error;
			});
		});
	}

	public static function buildContextInfoFromMedia(media : Media):Promise<MediaContextInfo> {
		return Promise.create({
			var driverPromise:Promise<PlaybackDriver> = media.getPlaybackDriver();
			driverPromise.then(function(driver : PlaybackDriver) {
				//return inf(media.provider, media, driver);
				var viewPromise:Promise<MediaRenderer> = media.getRenderer( driver );
				viewPromise.then(function( renderer ) {
					return inf(media.provider, media, driver, renderer);
				});
				viewPromise.unless(function(error : Dynamic) {
					throw error;
				});
			});
			driverPromise.unless(function(error : Dynamic) {
				throw error;
			});
		});
	}

	/**
	  * shorthand to create a MediaContextInfo object
	  */
	private static inline function inf(p:MediaProvider, m:Media, d:PlaybackDriver, v:MediaRenderer):MediaContextInfo {
		return {
			mediaProvider : p,
			media : m,
			playbackDriver : d,
			mediaRenderer : v
		};
	}
}
