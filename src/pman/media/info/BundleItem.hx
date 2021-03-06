package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.math.*;
import tannus.async.*;
import tannus.http.Url;

import gryffin.display.Image;

import pman.async.tasks.*;
import pman.media.info.BundleItemType;
import pman.bg.media.Dimensions;

import tannus.math.TMath.*;
//import electron.Tools.*;
import edis.Globals.*;
import pman.Globals.*;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.IteratorTools;
using tannus.async.Asyncs;

/**
  generally models assets stored in a particular media-item's "bundle" folder
 **/
class BundleItem {
    /* Constructor Function */
    public function new(bundle:Bundle, name:String):Void {
        this.bundle = bundle;
        this.name = name;
        this.type = Bundle.getBundleItemType( name );
    }

/* === Instance Methods === */

    /**
      * check whether [this] item is a thumbnail
      */
    public function isThumbnail():Bool {
        return type.match(Thumbnail(_));
    }

    /**
      * check whether [this] item is a snapshot
      */
    public function isSnapshot():Bool {
        return type.match(Snapshot(_));
    }

    /**
      get [this] item's dimensions
     **/
    public function getDimensions():Dimensions {
        return switch ( type ) {
            case Thumbnail( size ), Snapshot(_, size): size;
        }
    }

    /**
      get [this] item's time (if applicable)
     **/
    public function getTime():Maybe<Float> {
        return switch ( type ) {
            case Snapshot(time, _): time;
            default: null;
        };
    }

    /**
      * get the filesystem Path to [this] Bundle item
      */
    public function getPath():Path {
        return bundle.subpath( name );
    }

    /**
      * check that the underlying file exists
      */
    public function fexists():Bool {
        return Fs.exists(getPath());
    }

    /**
      * delete the file for [this] Bundle item
      */
    public function delete():Void {
        try {
            Fs.deleteFile(getPath());
        }
        catch (error : Dynamic) {
            trace('BundleItem.delete Error: $error');
        }
    }

    /**
      * get a URI for [this] BundleItem
      */
    public function getURI():String {
        return ('file://' + getPath());
    }

    /**
      get a Url object for [this] BundleItem
     **/
    public function getUrl():Url {
        return Url.fromString(getURI());
    }

    /**
      * load an Image from [this] BundleItem
      */
    @:access( gryffin.display.Image )
    public function toImage(?done : Cb<Image>):Image {
        var img = Image.load(getURI());
        if (done != null) {
            var sig = img.ready;
            sig.once(function() {
                defer(function() {
                    sig.once(function() {
                        done(null, img);
                    });
                });
            });
        }
        return img;
    }

    /**
      check whether [this] BundleItem refers to an Image file
     **/
    public function isImageItem():Bool {
        return type.match(Thumbnail(_)|Snapshot(_));
    }

/* === Instance Fields === */

    public var bundle : Bundle;
    public var name : String;
    public var type : BundleItemType;

    var _path: Null<Path> = null;
    var _uri: Null<Url> = null;
}
