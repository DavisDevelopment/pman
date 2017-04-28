package pman.media;

import tannus.ds.Promise;
import tannus.sys.Path;
import tannus.http.Url;

import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * class used to represent an Object that builds and provides the Media object
  */
class MediaProvider {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/**
	  * get the name of the Media that [this] will provide
	  */
	public function getName():String {
		switch ( src ) {
			case MediaSource.MSLocalPath( path ):
				return path.name;

			case MediaSource.MSUrl( url ):
				return url;
		}
	}

	/**
	  * get a URI that represents both the Media that [this] may provide,
	  * and information regarding how that media is being obtained
	  */
	public function getURI():String {
		switch ( src ) {
			case MediaSource.MSLocalPath( path ):
				return 'file://${path.normalize().toString()}';

			case MediaSource.MSUrl( url ):
				return url.toString();
		}
	}

	/**
	  * create the Media object
	  */
	public function getMedia():Promise<Media> {
		throw 'Not Implemented';
	}

/* === Serialization Methods === */

	/**
	  * Serialize [this]
	  */
	@:keep
	public function hxSerialize(s : Serializer):Void {
		s.serialize( src );
	}

	/**
	  * Unserialize a MediaProvider
	  */
	@:keep
	public function hxUnserialize(u : Unserializer):Void {
		src = u.unserialize();
	}

/* === Instance Fields === */

	public var src(default, null):MediaSource;
	public var type(default, null):MediaType;
}
