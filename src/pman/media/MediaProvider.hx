package pman.media;

import tannus.ds.Dict;
import tannus.ds.Promise;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaFeature;

import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.bg.URITools;

/**
  * class used to represent an Object that builds and provides the Media object
  */
class MediaProvider {
	/* Constructor Function */
	public function new():Void {
	    features = new Dict();
	    for (feat in MediaFeature.createAll()) {
	        features[feat] = false;
	    }
	}

/* === Instance Methods === */

	/**
	  * get the name of the Media that [this] will provide
	  */
	public function getName():String {
		return src.getTitle();
	}

	/**
	  * get a URI that represents both the Media that [this] may provide,
	  * and information regarding how that media is being obtained
	  */
	public function getURI():String {
		//return src.mediaSourceToUri();
		return src.toUri();
	}

	/**
	  * create the Media object
	  */
	public function getMedia():Promise<Media> {
		throw 'Not Implemented';
	}

	public function addFeatures(l: Iterable<MediaFeature>):Void {
	    for (x in l) {
	        features[x] = true;
	    }
	}

	public function hasFeature(x: MediaFeature):Bool {
	    return features.get( x );
	}

	public function hasFeatures(l: Iterable<MediaFeature>):Bool {
	    for (x in l) {
	        if (!hasFeature( x )) {
	            return false;
	        }
	    }
	    return true;
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
	public var features(default, null):Dict<MediaFeature, Bool>;
}
