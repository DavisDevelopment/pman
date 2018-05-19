package pman.ui.views.curses.models;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.ds.Vector;
import haxe.macro.Expr;

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
using tannus.macro.MacroTools;
#if !eval
using tannus.html.JSTools;
#end

/*
   base class for *.curses.models.Cell object
*/
@:allow( pman.ui.views.curses.models.CellRow )
class Cell {
    /* Constructor Function */
    public function new(?c:Char, ?fg:Color, ?bg:Color, ?bold:Bool, ?underline:Bool, ?invisible:Bool):Void {
        this.index = null;
        this.state = new CellState();
        _bindProps();

        //this.c = null;
        //this.fg = null;
        //this.bg = null;
        //this.bold = null;
        //this.underline = null;
        //this.invisible = null;

        // build state
        mod(c, fg, bg, bold, underline, invisible);
    }

/* === Instance Methods === */

    /**
      * reassign or modify the state of [this] Cell object
      */
    public function _assign(sparse:Bool, ?c:Char, ?fg:Color, ?bg:Color, ?bold:Bool, ?underline:Bool, ?invisible:Bool):Void {
        _a(sparse, this.c, c);
        _a(sparse, this.fg, fg);
        _a(sparse, this.bg, bg);
        _a(sparse, this.bold, bold);
        _a(sparse, this.underline, underline);
        _a(sparse, this.invisible, invisible);
    }

    /**
      * create and return a deep-copy of [this]
      */
    public function clone():Cell {
        return new Cell(c, fg, bg, bold, underline, invisible);
    }

    /**
      * reassign the state of [this] Cell object
      */
    public function set(?c:Char, ?fg:Color, ?bg:Color, ?bold:Bool, ?underline:Bool, ?invisible:Bool):Void {
        _assign(false, c, fg, bg, bold, underline, invisible);
    }

    /**
      * modify the state of [this] Cell object
      */
    public function mod(?c:Char, ?fg:Color, ?bg:Color, ?bold:Bool, ?underline:Bool, ?invisible:Bool):Void {
        _assign(true, c, fg, bg, bold, underline, invisible);
    }

    /**
      * does what [_assign] does, but pulled from an object
      */
    public function _ossign(sparse:Bool, o:CellDecl):Void {
        _assign(sparse, o.c, o.fg, o.bg, o.bold, o.underline, o.invisible);
    }

    /**
      * write [this]'s state from [d]
      */
    public function write(d: Either<Cell, CellDecl>):Void {
        var o:CellDecl = ((untyped d) : CellDecl);
        _ossign(false, o);
    }

    /**
      * merge the data in [d] onto [this] Cell
      */
    public function merge(d: Either<Cell, CellDecl>):Void {
        var o:CellDecl = ((untyped d) : CellDecl);
        _ossign(true, o);
    }

    /**
      * get a CharCellState from [this]
      */
#if !eval
    public function getState():CharacterMatrixState.CharCellState {
        return {
            a: {f:fg, b:bg},
            b: {b:bold, u:underline},
            c: c
        };
    }
#end

    /**
      get an object representation of [this] Cell's styling
     **/
    public function getStyleState():CellStyleDecl {
        return {
            bg: nullOr(bg, row.grid.bg),
            fg: nullOr(fg, row.grid.fg),
            underline: nullOr(underline, row.grid.underline, false),
            bold: nullOr(bold, row.grid.bold, false),
            invisible: nullOr(invisible, false)
        };
    }

    /**
      * assign a property value, and automagically flag as 'changed' if appropriate
      */
    private function _setProp<T>(name:String, value:T):T {
        var val = _getProp( name );
        if (val != value) {
            touch();
        }
        return state.nativeArraySet(name, value);
    }

    /**
      get the value of a property of [state]
     **/
    private function _getProp<T>(name: String):Null<T> {
        return state.nativeArrayGet( name );
    }

    /**
      bind properties from [state] onto [this]
     **/
    private function _bindProps() {
        var props = 'c,fg,bg,bold,underline,invisible'.split(',');
        for (prop in props) {
            defineProperty(prop, {
                get: _getProp.bind(prop),
                set: _setProp.bind(prop, _)
            });
        }
    }

    /**
      * check whether [this] has changed
      */
    public function hasChanged():Bool {
        return _changed;
    }

    /**
      * set the value of [_changed]
      */
    public function setChanged(v: Bool):Bool {
        return (_changed = v);
    }
    public function touch() setChanged( true );
    public function untouch() setChanged( false );

    /**
      bubble 'changed' status up hierarchy
     **/
    public function bubble():Void {
        if (hasChanged() && row != null) {
            row.alt(cast this);
            row.bubble();
        }
    }

/* === Instance Fields === */

    /* the index of [this] Cell in [row] */
    public var index: Null<Int>;

    public var c:Null<Char>;
    public var fg:Null<Color>;
    public var bg:Null<Color>;
    public var bold:Null<Bool>;
    public var underline:Null<Bool>;
    public var invisible:Null<Bool>;
    private var state: CellState;
    
    public var nextCell(default, null): Null<Cell>;
    public var row(default, null): Null<CellRow<Cell>>;
    
    private var _changed:Bool = false;
}

typedef CellDecl = {
    ?c:Char,
    ?fg:Color,
    ?bg:Color,
    ?bold:Bool,
    ?underline:Bool,
    ?invisible:Bool
};

typedef CellStyleDecl = {
    ?fg: Color,
    ?bg: Color,
    ?bold: Bool,
    ?underline: Bool,
    ?invisible: Bool
};

class CellState {
    /* Constructor Function */
    public function new():Void {
        defaults();
    }

/* === Instance Methods === */

    public function defaults():Void {
        c = null;
        fg = null;
        bg = null;
        bold = null;
        underline = null;
        invisible = false;
    }

/* === Instance Fields === */

    public var c: Null<Char>;
    public var fg: Null<Color>;
    public var bg: Null<Color>;
    public var bold: Null<Bool>;
    public var underline: Null<Bool>;
    public var invisible: Bool;
}
