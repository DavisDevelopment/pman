package pman.ui.views;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.async.*;

import pman.ui.views.CharacterMatrixViewStyle;

import gryffin.core.*;
import gryffin.display.*;

import haxe.extern.EitherType as Either;
import haxe.ds.Vector;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.ui.views.CharacterMatrixViewMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;

class CharacterMatrixViewBufferLineChar implements CharacterMatrixViewAccessor {
    /* Constructor Function */
    public function new(line:CharacterMatrixViewBufferLine, index:Int):Void {
        this.line = line;
        this.x = index;

        char = null;
        //style = CharacterMatrixViewStyle._null();
        style = null;
        changed = false;
    }

/* === Instance Methods === */

    /**
      * set [this]'s textual content
      */
    public function setChar(v: Null<Char>):Void {
        var d = (this.char != v);
        this.char = v;
        if ( d ) {
            touch();
        }
    }

    /**
      * apply some styles to [this]
      */
    public function applyStyle(style: Either<CharacterMatrixViewStyle, CharacterMatrixViewStyleDecl>):Void {
        var otherStyles:CharacterMatrixViewStyle = CharacterMatrixViewStyle.mdecl( style );
        if (this.style == null) {
            this.style = otherStyles;
        }
        else {
            this.style.applyOther( otherStyles );
        }
        touch();
    }

    /**
      * clear [this]'s styling
      */
    public function clearStyle():Void {
        style = null;
        touch();
    }

    /**
      * set the value of [changed], and inform the parent line if necessary
      */
    public inline function setChanged(v: Bool):Bool {
        changed = v;
        if ( changed ) {
            line.touch();
        }
        return changed;
    }

    /**
      * mark [this] character as changed
      */
    public function touch():Void setChanged( true );

    /**
      * mark [this] character as unchanged
      */
    public function untouch():Void setChanged( false );

    /**
      * react to having been culled from the rendering process, or in the case that the entire character-matrix has been dismantled
      */
    public function destroy():Void {
        x = -1;
        line = null;
        char = null;
        style = null;
        nextChar = null;
        changed = false;
    }

/* === Computed Instance Fields === */

    public var tty(get, never):CharacterMatrixView;
    private inline function get_tty() return line.tty;

    public var bufferWidth(get, never): Int;
    private inline function get_bufferWidth() return tty.width;

    public var bufferHeight(get, never): Int;
    private inline function get_bufferHeight() return tty.height;

    public var metrics(get, never): Area<Int>;
    private inline function get_metrics() return @:privateAccess tty.charMetrics;

    public var width(get, never): Int;
    private inline function get_width() return metrics.width;

    public var height(get, never): Int;
    private inline function get_height() return metrics.height;

    public var y(get, never): Int;
    private inline function get_y() return line.y;

/* === Instance Fields === */

    public var line: CharacterMatrixViewBufferLine;
    public var x: Int;

    public var char: Null<Char>;
    public var style: Null<CharacterMatrixViewStyle>;

    public var nextChar(default, null): Null<CharacterMatrixViewBufferLineChar>;
    public var changed(default, null): Bool;
}
