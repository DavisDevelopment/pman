package pman.ui.views;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.async.*;

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
using tannus.ds.IteratorTools;

class CharacterMatrixViewBuffer implements CharacterMatrixViewAccessor {
    /* Constructor Function */
    public function new(owner:CharacterMatrixView):Void {
        this.tty = owner;
        buildLines();
        this.cursor = new CharacterMatrixViewBufferCursor( tty );
    }

/* === Instance Methods === */

    public inline function line(y: Int):Null<CharacterMatrixViewBufferLine> {
        return lines.get( y );
    }

    public inline function column(y:Int, x:Int):Null<CharacterMatrixViewBufferLineChar> {
        return line( y ).col( x );
    }

    public inline function getChar(y:Int, x:Int):Null<Char> return column(y, x).char;
    public inline function setChar(y:Int, x:Int, ch:Null<Char>):Void return column(y, x).setChar( ch );
    public inline function insertChar(y:Int, x:Int, ch:Null<Char>):Void return line( y ).insertChar(x, ch);
    public inline function clearChar(y:Int, x:Int):Void line( y ).clearChar( x );
    public inline function clearLine(y:Int, ?start:Int, ?end:Int):Void line( y ).clear(start, end);
    public inline function getLineText(y:Int, ?start:Int, ?end:Int):String return line( y ).getText(start, end);
    public inline function writeLineText(y:Int, txt:String, ?pos:Int, ?len:Int, ?offset:Int):Void line( y ).writeText(txt, pos, len, offset);
    public inline function getLineLength(y: Int):Int return line( y ).endX();
    public inline function deleteChar(y:Int, x:Int):Void return line( y ).deleteChar( x );

    /**
      * force [this] line to be repainted
      */
    public inline function refreshLine(y: Int):Void {
        lines[y].touch();
        lines[y].touchAllChars();
    }

    /**
      * force many lines to be repainted
      */
    public function refreshLines(ys: Array<Int>):Void {
        for (y in ys)
            refreshLine( y );
    }

    /**
      * repaint all lines within a given y-range
      */
    public inline function refreshLineRange(y1:Int, y2:Int):Void {
        for (y in (y1...y2)) {
            refreshLine( y );
        }
    }

    /**
      *
      */
    public function deleteLine(y:Int):Null<CharacterMatrixViewBufferLine> {
        var line = lines.get( y );
        if (line != null) {
            lines[y] = new CharacterMatrixViewBufferLine(this, y);
            //TODO let [line] know it's being deleted
            refreshLine( y );
        }
        return line;
    }

    /**
      * synchronize a line's index in [lines] with the value of its 'y' property
      * if [bias] is true, then its position in [lines] is found, and 'y' is set to that.
      * conversely, if [bias] is false, its position in [lines] is set it the value of 'y'
      */
    public function reconcileLineIndex(line:CharacterMatrixViewBufferLine, bias:Bool):Void {
        if ( bias ) {
            var index:Int = -1;
            for (i in 0...lines.length) {
                if (lines[i] == line) {
                    index = i;
                    break;
                }
            }
            line.y = index;
            lines[index] = line;
        }
        else {
            lines.set(line.y, line);
        }
    }

      * move a line from one index to another
      */
    public inline function moveLine(line:CharacterMatrixViewBufferLine, newY:Int):Void {
        line.y = newY;
        lines[newY] = line;
    }

    /**
      * swap two lines' positions
      */
    public inline function swapLines(y1:Int, y2:Int):Void {
        var tmp = lines[y1];
        if (tmp == null) {
            throw 'Error';
        }
        else {
            moveLine(lines[y2], y1);
            moveLine(tmp, y2);
        }
    }

    /**
      * insert a new blank line at [y]
      */
    public function insertNewLine(y: Int):Void {
        shiftDown( y );
        deleteLine( y );
    }

    /**
      * shift all lines down
      */
    public function shiftDown(startY:Int=0, ?endY:Int):Void {
        if (endY == null) {
            endY = (height - 1);
        }
        var i:Int = endY;
        while (--i >= startY) {
            moveLine(lines[i], (i + 1));
        }
    }

    /**
      * shift all lines up
      */
    public function shiftUp(startY:Int=0, ?endY:Int):Void {
        if (endY == null) endY = (height - 1);
        var i:Int = startY;
        while (i++ < endY) {
            moveLine(lines[i + 1], i);
        }
    }

    /**
      * build out the [lines] property
      */
    private function buildLines():Void {
        lines = new Vector( height );
        var line: CharacterMatrixViewBufferLine;
        for (y in 0...height) {
            line = new CharacterMatrixViewBufferLine(this, y);
            lines.set(y, line);
        }
    }

    /**
      * check if [this] is changed
      */
    public function isChanged():Bool {
        for (l in itLines()) {
            if (l.isChanged()) {
                return true;
            }
        }
        return false;
    }

    public function itLines():Iterator<CharacterMatrixViewBufferLine> {
        return (0...height).map.fn(line(_));
    }

    /**
      * assign the value of [changed]
      */
    public inline function setChanged(value: Bool):Bool {
        return (changed = value);
    }

    /**
      * mark [this] as having changed since last update
      */
    public inline function touch():Void setChanged( true );
    public inline function untouch():Void setChanged( false );

/* === Computed Instance Fields === */

    public var width(get, never): Int;
    private inline function get_width() return tty.width;

    public var height(get, never): Int;
    private inline function get_height() return tty.height;

    public var charMetrics(get, never): Area<Int>;
    private inline function get_charMetrics() return @:privateAccess tty.charMetrics;

/* === Instance Fields === */

    public var tty: CharacterMatrixView;
    public var cursor: CharacterMatrixViewBufferCursor;

    public var lines: Vector<CharacterMatrixViewBufferLine>;

    private var changed:Bool = false;
}
