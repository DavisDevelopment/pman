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
using tannus.FunctionTools;
using tannus.ds.IteratorTools;

class CharacterMatrixViewBufferLine implements CharacterMatrixViewAccessor {
    /* Constructor Function */
    public function new(owner:CharacterMatrixViewBuffer, index:Int):Void {
        buffer = owner;
        y = index;

        buildCols();
    }

/* === Instance Methods === */

    /**
      * build out each character
      */
    private function buildCols():Void {
        cols = new Vector( bufferWidth );
        var col:CharacterMatrixViewBufferLineChar;
        for (x in 0...bufferWidth) {
            col = new CharacterMatrixViewBufferLineChar(this, x);
            cols.set(x, col);
            var prev = cols.get(x - 1);
            if (prev != null) {
                @:privateAccess prev.nextChar = col;
            }
        }
    }

    /**
      * get a single column by its index
      */
    public inline function col(x: Int):Null<CharacterMatrixViewBufferLineChar> {
        return cols.get( x );
    }

    /**
      * iterate over the chars
      */
    public function chars():Iterator<CharacterMatrixViewBufferLineChar> {
        return (0...bufferWidth).map.fn(col( _ ));
    }

    /**
      * apply the given function to the styles of every char on [this] line
      */
    public inline function fstyleEach(action:CharacterMatrixViewStyle->Bool, ?test:CharacterMatrixViewStyle->Bool):Void {
        for (x in 0...bufferWidth) {
            if (test != null ? test(col( x ).style) : true) {
                if (!action(col( x ).style)) {
                    break;
                }
            }
        }
    }

    /**
      * get the textual content of [this] line
      */
    public function getText(?start:Int, ?end:Int, ?emptyChar:Char, trim:Bool=true):String {
        if (start == null) start = 0;
        if (end == null) end = (bufferWidth - 1);
        if (emptyChar == null) emptyChar = ' ';
        start = start.clamp(0, bufferWidth);
        end = min(end, (bufferWidth - 1));

        var result:String = '';
        var column:CharacterMatrixViewBufferLineChar;
        for (x in start...end) {
            column = col( x );
            
            if (column.char == null) {
                result += emptyChar.toString();
            }
            else {
                result += column.char.toString();
            }
        }

        if ( trim ) {
            result = result.trim();
        }

        return result;
    }

    /**
      * write some text onto [this] line
      */
    public function writeText(text:String, ?pos:Int, ?len:Int, ?offset:Int):Void {
        if (pos == null) pos = 0;
        if (len == null) len = text.length;
        if (offset == null) offset = 0;

        var txti:Int = 0;
        fic(function(c, x) {
            setChar(x, text.charAt(pos + txti++));
            return true;
        }, offset);
    }

    /**
      * set the char content at column [x]
      */
    public inline function setChar(x:Int, ch:Null<Char>):Void {
        col( x ).setChar( ch );
    }

    /**
      * insert a character at the given index, shifting all characters after it to the right
      */
    public function insertChar(x:Int, ch:Char):Void {
        var after = schars(getText(x + 1));
        setChar(x, ch);
        for (ch in after) {
            setChar(++x, ch);
        }
    }

    /**
      *
      */
    public function deleteChar(x: Int):Void {
        var after = getText(x + 1);
        clear( x );
        writeText(after, 0, null, x);
    }

    /**
      * stick [ch] onto the end of [this] line
      */
    public function appendChar(ch: Char):Void {
        var ex = endX() + 1;
        if (ex < (bufferWidth - 1)) {
            setChar(ex, ch);
        }
        else {
            //TODO
        }
    }

    /**
      * get a character by column
      */
    public inline function getChar(x: Int):Null<Char> return col( x ).char;

    /**
      * clear the character content from the column specified by [x]
      */
    public inline function clearChar(x: Int):Void return setChar(x, null);

    /**
      * clear part or all of [this] line
      */
    public function clear(?start:Int, ?end:Int):Void {
        fic(function(c, x) {
            clearChar( x );
            return true;
        }, start, end);
    }

    /**
      * move all content of [this] line to the left by [n]
      */
    public function shiftLeft(start:Int=0, ?end:Int):Void {
        if (end == null) {
            end = (bufferWidth - 1);
        }

        var txt:Array<String> = [];
        if (start != 0) {
            txt.push(getText(0, start));
        }
        else {
            txt.push('');
        }
        txt.push(getText(start, end));
        if (end != (bufferWidth - 1)) {
            txt.push(getText(end, (bufferWidth - 1)));
        }
        else {
            txt.push('');
        }

        var out:String = '';
        switch ( txt ) {
            case [_]:
                out = txt[0] = (txt[0].slice( 1 ) + ' ');

            case [pre, sel, post]:
                if (!pre.empty())
                    out += pre.slice(0, -1);
                if (pre.empty())
                    out += sel.slice( 1 );
                else
                    out += sel;
                out += ' ';
                out += post;
        }
        clear();
        writeText( out );
    }

    /**
      * move all content of [this] line to the left by [n]
      */
    public function shiftRight(n: Int):Void {
        var txt = getText();
        clear();
        txt = (' '.times( n ) + txt);
        writeText( txt );
    }

    /**
      * get the offset of the last column that has a non-null character value
      */
    public function endX():Int {
        var i:Int = bufferWidth;
        while (--i >= 0) {
            if (getChar( i ) != null) {
                return i;
            }
        }
        return 0;
    }

    /**
      * functional iteration over columns
      */
    private function fic(action:CharacterMatrixViewBufferLineChar->Int->Bool, ?start:Int, ?end:Int):Void {
        if (start == null) start = 0;
        if (end == null) end = (bufferWidth - 1);
        for (i in (start...end)) {
            if (!action(col(i), i)) {
                return ;
            }
        }
    }

    /**
      * check whether [this] is changed
      */
    public inline function isChanged():Bool {
        return changed;
    }

    /**
      * mark a set of character cells as having changed
      */
    public function setCharChanged(startX:Int, ?endX:Int, v:Bool):Void {
        endX = nullOr(endX, (startX + 1));
        fic(function(c, x) {
            c.setChanged( v );
            return true;
        }, startX, endX);
    }
    public function touchChar(startX:Int, ?endX:Int):Void setCharChanged(startX, endX, true);
    public function untouchChar(startX:Int, ?endX:Int):Void setCharChanged(startX, endX, false);

    /**
      * set the value of [changed] for all cells on [this] row
      */
    public function setAllCharsChanged(v: Bool):Void {
        var cc = cols[0];
        while (cc != null) {
            cc.setChanged( v );
            cc = cc.nextChar;
        }
    }
    public function touchAllChars():Void setAllCharsChanged( true );
    public function untouchAllChars():Void setAllCharsChanged( false );

    /**
      * set the value of [changed]
      */
    public function setChanged(value:Bool):Bool {
        changed = value;
        if ( changed ) {
            buffer.touch();
        }
        return changed;
    }
    public function touch():Void setChanged( true );
    public function untouch():Void setChanged( false );

    /**
      * map [charset] onto [this] line
      */
    public function writeChars(charset:Array<Char>, ?sx:Int, ?ex:Int):Void {
        if (sx == null) sx = 0;
        if (ex == null) ex = bufferWidth;
        for (i in 0...(ex - sx)) {
            cols[sx + i].setChar(charset[i]);
            cols[sx + i].touch();
        }
    }

    public function getChars(?sx:Int, ?ex:Int):Array<Char> {
        if (sx == null) sx = 0;
        if (ex == null) ex = bufferWidth;
        return schars(getText(sx, ex));
    }

    public function ioChars(?t:Array<Char>->Array<Char>, ?col:CharacterMatrixViewBufferLineChar->Void, ?sx:Int, ?ex:Int):Void {
        if (sx == null) sx = 0;
        if (ex == null) ex = bufferWidth;

        var charset = getChars(sx, ex);
        if (t != null)
            charset = t( charset );

        for (i in 0...(ex - sx)) {
            var cc = cols[sx + i];
            if (cc != null) {
                cc.setChar(charset[i]);
                if (col != null)
                    col( cc );
                cc.touch();
            }
        }
    }

    public function mapChars(map:Char->Char, col:CharacterMatrixViewBufferLineChar->Void, ?sx:Int, ?ex:Int):Void {
        if (sx == null) sx = 0;
        if (ex == null) ex = bufferWidth;
        var charset = getChars(sx, ex);
        for (i in 0...(ex - sx)) {
            var cc = cols[sx + i];
            if (cc != null) {
                cc.setChar(charset[i] != null ? map(charset[i]) : null);
                col( cc );
                cc.touch();
            }
        }
    }

    /**
      * react to having been culled from the rendering process, or in the case that the entire character-matrix has been dismantled
      */
    public function destroy():Void {
        for (x in 0...bufferWidth) {
            cols[x].destroy();
        }
        cols = null;
        buffer = null;
        y = -1;
    }

    private static inline function schars(s: String):Array<Char> return (s.split('') : Array<Char>);

/* === Computed Instance Fields === */

    public var bufferWidth(get, never): Int;
    private inline function get_bufferWidth() return tty.width;

    public var bufferHeight(get, never): Int;
    private inline function get_bufferHeight() return tty.height;

    public var charMetrics(get, never): Area<Int>;
    private inline function get_charMetrics() return @:privateAccess tty.charMetrics;

    public var tty(get, never): CharacterMatrixView;
    private inline function get_tty() return buffer.tty;

/* === Instance Fields === */

    public var buffer: CharacterMatrixViewBuffer;
    public var y: Int;

    public var cols: Vector<CharacterMatrixViewBufferLineChar>;

    private var changed:Bool = false;
}
