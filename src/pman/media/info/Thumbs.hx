package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.math.*;

import gryffin.display.Image;

import pman.async.*;
import pman.media.info.Bundle;

import tannus.math.TMath.*;
import electron.Tools.*;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.IteratorTools;

@:forward
abstract Thumbs (CThumbs) from CThumbs to CThumbs {
    public inline function new(bundle:Bundle, count:Int, size:String):Void {
        this = new CThumbs(bundle, count, size);
    }

    @:arrayAccess
    public inline function get(index : Int):Null<Image> return this.get( index );
}

@:access( pman.media.info.Bundle )
class CThumbs {
    /* Constructor Function */
    public function new(bundle:Bundle, count:Int, size:String):Void {
        this.bundle = bundle;
        this.count = count;
        var ss = bundle.sizeDimensions( size );
        this.size = [ss.w, ss.h];

        this._items = bundle.getSetItems(count, size);
        //haxe.ds.ArraySort.sort(this._items, function(x:BundleItem, y:BundleItem) {
            //return Reflect.compare(x.set.i, y.set.i);
        //});
        this.thumbs = [for (i in 0...length) null];
    }

/* === Instance Methods === */

    /**
      * get a thumbnail image by index
      */
    public function get(index : Int):Null<Image> {
        if (index >= 0 && index <= (_items.length - 1) && _items[index] != null) {
            if (thumbs[index] == null) {
                return thumbs[index] = bundle.get(_items[index]);
            }
            else return thumbs[index];
        }
        else {
            return null;
        }
    }

    /**
      * iterate over all images in [this] thumbnail set
      */
    public function iterator():Iterator<Image> {
        return (0...length).map( get );
    }

    /**
      * iterate over the items that make up [this] thumbnail set
      */
    public function items():Iterator<BundleItem> {
        return _items.iterator();
    }

/* === Computed Instance Fields === */

    public var length(get, never):Int;
    private inline function get_length() return count;

    public var width(get, never):Int;
    private inline function get_width() return size[0];

    public var height(get, never):Int;
    private inline function get_height() return size[1];

/* === Instance Fields === */

    public var bundle : Bundle;
    public var count : Int;

    private var size : Array<Int>;
    private var _items : Array<BundleItem>;
    private var thumbs : Array<Null<Image>>;
}
