package pman.models;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.graphics.Color;

import Slambda.fn;
import tannus.math.TMath.*;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;

abstract Image (ImageObject) from ImageObject to ImageObject {
    public inline function new(img) {
        this = img;
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var width(get, never): Int;
    inline function get_width() return this.getWidth();

    public var height(get, never): Int;
    inline function get_height() return this.getHeight();

    public var source(get, never): String;
    inline function get_source() return this.getSource();

/* === Factory Methods === */

}

#if (renderer_process || worker)
interface ImageObject extends gryffin.display.Paintable {
#else
interface ImageObject {
#end
    function getWidth(): Int;
    function getHeight(): Int;
    function getSource(): String;
    
    //#if (renderer_process || worker)
    //function paint(c:gryffin.display.Ctx, src:Rect<Float>, dest:Float<Float>):Void;
    //#end
}
