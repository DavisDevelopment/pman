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

import pman.ui.views.CharacterMatrixViewStyle;

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

@:access( pman.ui.views.CharacterMatrixView )
class CharacterMatrixViewBufferCursor implements CharacterMatrixViewAccessor {
    /* Constructor Function */
    public function new(tty: CharacterMatrixView):Void {
        this.tty = tty;
        line = 0;
        column = 0;

        savedStates = new Stack();
        styles = null;
    }

/* === Instance Methods === */

    /**
      * save [this] cursor's current position
      */
    public function save():Void {
        savedStates.add(_index());
    }

    /**
      * restore the last-saved position
      */
    public function restore():Void {
        var saved:Null<Int> = savedStates.pop();
        if (saved == null) {
            throw 'Error: No state to restore to';
        }
        goto(_pos( saved ));
    }

    /**
      * move [this] cursor to [y, x]
      */
    public function moveTo(y:Int, x:Int):Void {
        line = y;
        column = x;
    }

    /**
      * move to the given Point<int>
      */
    public function moveToPoint(pos: Point<Int>):Void {
        moveTo(pos.y, pos.x);
    }

    /**
      * move [this] cursor from its current position by [y, x]
      */
    public function move(?y:Int, ?x:Int):Void {
        qm(y, line += _);
        qm(x, column += _);
    }

    /**
      * transform the content of the specified line
      */
    public function lioc(?f:Array<Char>->Array<Char>, ?cf:CharacterMatrixViewBufferLineChar->Void, ?y:Int, ?sx:Int, ?ex:Int):Void {
        save();
        ln(y).ioChars(f, cf, sx, ex);
        restore();
    }

    /**
      * set the character at cell(y, x) and move 1 cell to the right
      */
    public function putChar(c:Char, ?y:Int, ?x:Int):Void {
        col(_y(y), _x(x)).setChar( c );
        stych(y, x);
        advance();
    }

    /**
      * insert a character at [y, x], and move 1 character to the right
      */
    public function insertChar(c:Char, ?y:Int, ?x:Int):Void {
        ln(_y( y )).insertChar(_x(x), c);
        stych(y, x);
        advance();
    }

    /**
      * set text content starting at [y, x]
      */
    public function putText(s:String, ?y:Int, ?x:Int):Void {
        // keep track of how far we've gone
        var delta:Point<Int> = new Point();
        // save where we are now
        save();
        // navigate to specified new position (if any)
        _nav(y, x);
        // create variable for holding our 'current' char and a temp value for changing [column]
        var c:Char, tmp:Int;
        // iterate over every char in [s]
        for (i in 0...s.length) {
            // grab that char
            c = (s.charAt( i ) : Char);
            // check whether it's a line-breaking character
            if (c.isLineBreaking()) {
                // grab [column] value
                tmp = column;
                // jump ahead to the next line
                nextLine();
                // reset [column] to 0
                column = 0;
                // adjust [delta] for the movement down+backward
                delta.x += -tmp;
                delta.y += 1;
            }
            else {
                // push [c] onto the line
                putChar( c );
                // move [delta] forward 
                delta.x += 1;
            }
        }
        // restore to starting position
        restore();
        // move relative to current position by [delta]
        move(delta.y, delta.x);
    }

    /**
      * insert text starting at [y, x]
      */
    public function insertText(s:String, ?y:Int, ?x:Int):Void {
        // keep track of how far we've gone
        var delta:Point<Int> = new Point();
        // save where we are now
        save();
        // navigate to specified new position (if any)
        _nav(y, x);
        // create variable for holding our 'current' char and a temp value for changing [column]
        var c:Char, tmp:Int;
        // iterate over every char in [s]
        for (i in 0...s.length) {
            // grab that char
            c = (s.charAt( i ) : Char);
            // check whether it's a line-breaking character
            if (c.isLineBreaking()) {
                // grab [column] value
                tmp = column;
                // jump ahead to the next line
                nextLine();
                // reset [column] to 0
                column = 0;
                // adjust [delta] for the movement down+backward
                delta.x += -tmp;
                delta.y += 1;
            }
            else {
                // push [c] onto the line
                insertChar( c );
                // move [delta] forward 
                delta.x += 1;
            }
        }
        // restore to starting position
        restore();
        // move relative to current position by [delta]
        move(delta.y, delta.x);
    }

    /**
      * replace [what] with [with] on either a single given line, or all of them
      */
    public function replaceText(what:String, with:String, ?y:Int):Void {
        // if [y] is not provided, iterate over all 'y' values
        if (y == null) {
            for (y in 0...buffer.height) {
                replaceText(what, with, y);
            }
        }
        // otherwise
        else {
            // set [line] to [y]
            if (y != line)
                line = y;
            // build a regular expression from [what]
            var preg:PRegEx = new PRegEx();
            var reg = preg.then(what, false, true).toRegEx();
            // do the replacement
            var retext = reg.map(getLineText(), function(reg: RegEx) {
                // concatenate the text preceding the 'match', the replacement text, and the text after the match
                var result:String = (reg.matchedLeft() + with + reg.matchedRight());
                return result;
            });
            // ensure that [retext] is not larger than the buffer for this line
            if (retext.length > buffer.width) {
                // truncate it if necessary
                retext = retext.substr(0, buffer.width);
            }
            // reset [column] to 0
            column = 0;
            // overwrite [retext] over [this] line
            putText(retext, line, 0);
        }
    }

    /**
      * "erase" the text from a line
      */
    public function clearLine(?y:Int, ?sx:Int, ?ex:Int, ?emptyChar:Char):Void {
        save();
        if (sx == null) {
            sx = 0;
        }
        if (ex == null) {
            ex = tty.width;
        }
        var cc = col(y, sx);
        while (cc != null && cc.x != ex) {
            cc.setChar( emptyChar );
            stych( cc );
            //cc.touch();
        }
        var row = ln( y );
        if (row != null) {
            row.touch();
        }
        //moveTo(_y(y), sx);
        //for (x in sx...ex) {
            //var cc = col();
            //if (cc == null) {
                //throw '[$sx, $ex] OutOfBounds';
            //}
            //else {
                //cc.setChar( emptyChar );
            //}
        //}
        //buffer.refreshLine( line );
        restore();
    }

    /**
      * delete a line
      */
    public function deleteLine(?y: Int):Null<CharacterMatrixViewBufferLine> {
        buffer.deleteLine(_y( y ));
        buffer.refreshLine(_y( y ));
    }

    /**
      * swap two lines with one another
      */
    public function swapLines(y1:Int, ?y2:Int):Void {
        buffer.swapLines(y1, _y( y2 ));
        buffer.refreshLines([_y( y1 ), _y( y2 )]);
    }

    /**
      * move [line] to [newY]
      */
    public function moveLine(?line:CharacterMatrixViewBufferLine, ?newY:Int):Void {
        if (line == null && newY == null) {
            return ;
        }
        else if (line == null) {
            line = ln();
        }
        else if (newY == null) {
            newY = _y( newY );
        }
        buffer.moveLine(line, newY);
        buffer.refreshLine( newY );
    }

    /**
      * navigate to the end of the line
      */
    public function gotoEndOfLine(?y: Int):Void {
        save();
        var l = ln( y );
        var i = tty.width;
        while (--i >= 0) {
            if (getChar(null, i) != null) {
                break;
            }
        }
        restore();
        moveTo(_y(y), i);
    }

    /**
      * insert a new blank line
      */
    public function insertNewLine(?y: Int):Void {
        buffer.insertNewLine(_y( y ));
        nextLine();
    }

    /**
      * shift line down
      */
    public function shiftLineDown(?startY:Int, ?endY:Int):Void {
        buffer.shiftDown(_y( startY ), endY);
    }

    /**
      * shift line up
      */
    public function shiftLineUp(?startY:Int, ?endY:Int):Void {
        buffer.shiftUp(_y( startY ), endY);
    }

    /**
      * get the cell's [char] value
      */
    public function getChar(?y:Int, ?x:Int):Null<Char> {
        return ncol(y, x).ternary(_.char, null);
    }

    /**
      * get a line's text
      */
    public function getLineText(?y:Int, ?emptyChar:Char, ?start:Int, ?end:Int, ?trim:Bool):String {
        return mln( y ).ternary(_.getText(start, end, emptyChar, trim), null);
    }

    /**
      * get the cell's styling
      */
    public function getCharStyle(?y:Int, ?x:Int):Null<CharacterMatrixViewStyle> {
        return ncol(y, x).ternary(_.style, null);
    }

    /**
      * set a cell's styling
      */
    public function setCharStyle(style:Either<CharacterMatrixViewStyle,CharacterMatrixViewStyleDecl>, ?y:Int, ?x:Int):Void {
        ncol(y, x).attempt(_.applyStyle( style ));
    }

    /**
      * set a cell-range styling
      */
    public function setCharRangeStyle(style:Either<CharacterMatrixViewStyle,CharacterMatrixViewStyleDecl>, ?y:Int, ?startX:Int, ?endX:Int):Void {
        moveTo(_y(y), _x(startX));
        if (endX == null) {
            endX = (tty.width - 1);
        }
        for (x in _x(startX)...endX) {
            setCharStyle(style, null, x);
        }
    }

    /**
      * set a line's styling
      */
    public function setLineStyle(style: Either<CharacterMatrixViewStyle, CharacterMatrixViewStyleDecl>, ?start:Int, ?end:Int, ?y:Int):Void {
        setCharRangeStyle(style, y, start, end);
    }

    /**
      * delete [len] chars, starting at [y, x]
      */
    public function delete(?len:Int, ?y:Int, ?x:Int):Void {
        //_nav(y, x);
        save();
        var c:Char;
        var cc:CharacterMatrixViewBufferLineChar;
        var deleted:Int = 0, y1:Int = line;
        var index:Int = _index(y, x);
        while ( true ) {
            cc = pcol(_pos( index++ ));
            if (cc == null) {
                return ;
            }
            else if (cc.char == null) {
                return ;
            }
            else {
                cc.setChar( null );
                deleted++;
                if (len != null && deleted >= len) {
                    return ;
                }
            }
        }
        var y2:Int = line;
        if (y1 == y2) {
            buffer.refreshLine( y1 );
        }
        else {
            buffer.refreshLineRange(y1, y2);
        }
        restore();
    }

    /**
      * delete the character to the left of [this] cursor
      */
    public function deleteLeft():Void {
        ln().shiftLeft( column );
        back();
    }

    /**
      * delete the character to the right of [this] cursor
      */
    public function deleteRight():Void {
        column -= 1;
        deleteLeft();
    }

    /**
      * copy the content of [srcLine], starting at [srcStart] and ending at [srcEnd], onto [destLine] starting at [destCol]
      */
    public function blit(srcLine:Int, ?srcStart:Int, ?srcEnd:Int, ?destLine:Int, ?destCol:Int):Void {
        var txt:String = ln( srcLine ).getText(srcStart, srcEnd);
        moveTo(_y( destLine ), _x( destCol ));
        ln().writeText(txt, 0, null, _x( destCol ));
    }

    /**
      * goto the next line
      */
    public inline function nextLine():Void {
        line++;
        column = 0;
    }

    /**
      * goto the previous line
      */
    public inline function prevLine():Void {
        line--;
        gotoEndOfLine();
    }

    /**
      * set the color of the actual text itself
      */
    public function setTextColor(v: Null<Color>):Null<Color> {
        enstyl();
        styles.setForegroundColor( v );
        return styles.foregroundColor;
    }

    /**
      * set the background-color for the text
      */
    public function setBackgroundColor(v: Null<Color>):Null<Color> {
        enstyl();
        styles.setBackgroundColor( v );
        return styles.backgroundColor;
    }

    /**
      * set whether the text is emboldened
      */
    public function setBold(v: Bool):Bool {
        enstyl();
        styles.setBold( v );
        return styles.bold;
    }

    /**
      * set whether text is italicized
      */
    public function setItalic(v: Bool):Bool {
        enstyl();
        styles.setItalic( v );
        return styles.italic;
    }

    /**
      * set whether text is underlined
      */
    public function setUnderline(v: Bool):Bool {
        enstyl();
        styles.setUnderline( v );
        return styles.underline;
    }

    /**
      * assign the decoration given to textual characters
      */
    public function setTextDecoration(?bold:Bool, ?italic:Bool, ?underline:Bool):Void {
        qm(bold, setBold(_));
        qm(italic, setItalic(_));
        qm(underline, setUnderline(_));
    }

/* === Utility Methods === */

    /**
      * iterate over a certain subset of cells
      */
    private function chars(f:CharacterMatrixViewBufferLineChar->Int->Void, y:Int, ?x1:Int, ?x2:Int):Void {
        x1 = nullOr(x1, 0);
        x2 = nullOr(x2, tty.width);
        //var it = (x1...x2).map.fn(col(y, _));
        for (index in x1...x2) {
            f(col(y, index), index);
        }
    }

    /**
      * (sty)le (char)acter
      */
    private function stych(?y:Int, ?x:Int, ?c:CharacterMatrixViewBufferLineChar):Void {
        var cc = (c != null ? c : col(y, x));
        if (cc == null)
            return ;
        if (styles == null) {
            cc.clearStyle();
        }
        else {
            cc.applyStyle( styles );
        }
    }

    private inline function ensureStyles():Void {
        if (styles == null)
            styles = new CharacterMatrixViewStyle();
    }
    private inline function enstyl():Void ensureStyles();

    /**
      * get the buffer for [this] view
      */
    private function b():Null<CharacterMatrixViewBuffer> return tty.buffer;

    /**
      * get the line specified by [y]
      */
    private function ln(?y: Int):Null<CharacterMatrixViewBufferLine> return b().line(nullOr(y, line));
    private function mln(?y: Int):Maybe<CharacterMatrixViewBufferLine> return ln( y );

    /**
      * get the cell specified by (y, x)
      */
    private function col(?y:Int, ?x:Int):Null<CharacterMatrixViewBufferLineChar> return b().line(nullOr(y, line)).col(nullOr(x, column));
    private inline function pcol(pos: Point<Int>):Null<CharacterMatrixViewBufferLineChar> return col(pos.y, pos.x);
    private inline function ncol(?y:Int, ?x:Int):Maybe<CharacterMatrixViewBufferLineChar> {
        _nav(y, x);
        return col();
    }

    /**
      * return the value of either the provided [y] argument, or the [line] property
      */
    private inline function _y(?y: Int):Int return nullOr(y, line);

    /**
      * return the value of either the provided [x] argument, or the [column] property
      */
    private inline function _x(?x: Int):Int return nullOr(x, column);

    /**
      * navigate [this] cursor, as much as can be done, to the provided position
      */
    public inline function _nav(?y:Int, ?x:Int):Void {
        moveTo(_y(y), _x(x));
    }

    /**
      * get the Point-position of [index]
      */
    private inline function _pos(index: Int):Point<Int> {
        return new Point(int(index % tty.width), int(index / tty.width));
    }
    public inline function getCursorPos():Point<Int> return _pos(_index());

    /**
      * get the absolute index of [y, x]
      */
    private inline function _index(?y:Int, ?x:Int):Int {
        return ((_y( y ) * tty.width) + _x( x ));
    }

    /**
      * move forward by one cell
      */
    private inline function advance():Void { move(null, 1); }
    private inline function back():Void move(null, -1);

    /**
      * move to the given Point<Int>
      */
    private inline function goto(pos: Point<Int>):Void {
        moveTo(pos.y, pos.x);
    }

    /**
      * reset [this] styles
      */
    private inline function _resetStyles():Void {
        styles = null;
    }

/* === Computed Instance Fields === */

    public var buffer(get, never):CharacterMatrixViewBuffer;
    private inline function get_buffer() return tty.buffer;

/* === Instance Fields === */

    public var tty: CharacterMatrixView;
    public var line(default, null): Int;
    public var column(default, null): Int;

    private var savedStates: Stack<Int>;
    private var styles: Null<CharacterMatrixViewStyle>;
}
