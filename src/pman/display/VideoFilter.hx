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

/* === Instance Fields === */

    public var type : VideoFilterType;

/* === Static Methods === */

    /**
      * create a VideoFilter from a String
      */
    public static function fromString(s : String):VideoFilter {
        return new VideoFilter(s.fromString());
    }
}
