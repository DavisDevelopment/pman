package pman.display;

import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.geom.Angle;

import pman.display.VideoFilterType;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using pman.display.VideoFilterTools;

@:forward
abstract VideoFilter (CVideoFilter) from CVideoFilter {
    /* Constructor Function */
    public inline function new(type : VideoFilterType):Void {
        this = new CVideoFilter( type );
    }

    @:to
    public inline function toString():String return this.toString();

    @:from
    public static inline function fromString(s : String):VideoFilter return CVideoFilter.fromString( s );
}

@:expose('VideoFilter')
class CVideoFilter {
    /* Constructor Function */
    public function new(type : VideoFilterType):Void {
        this.type = type;
    }

/* === Instance Methods === */

    /**
      * print [this] to a String
      */
    public function toString():String {
        return type.toString();
    }

    public inline function applyToPixels(pixels : gryffin.display.Pixels) {
        type.applyToPixels( pixels );
    }

/* === Instance Fields === */

    public var type : VideoFilterType;

/* === Static Methods === */

    /**
      * create a VideoFilter from a String
      */
    public static function fromString(s : String):VideoFilter {
        return new VideoFilter(s.fromString());
    }

    /**
      * create a VideoFilter from an untyped value
      */
    public static function fromDynamic(x : Dynamic):VideoFilter {
        if ((x is String)) {
            return fromString(cast x);
        }
        else if ((x is CVideoFilter)) {
            return cast x;
        }
        else if ((x is VideoFilterType)) {
            return new VideoFilter(cast x);
        }
        else {
            try {
                return fromString(Std.string( x ));
            }
            catch (error : Dynamic) {
                throw 'Cannot create VideoFilter from $x';
            }
        }
    }
}
