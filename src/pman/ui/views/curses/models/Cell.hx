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
        this.c = null;
        this.fg = null;
        this.bg = null;
        this.bold = null;
        this.underline = null;
        this.invisible = null;

        // bind setters
        var props = ['c', 'fg', 'bg', 'bold', 'underline', 'invisible'];
        for (prop in props) {
            defineSetter(prop, _prop_set.bind(prop, _));
        }

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
      * assign a property value, and automagically flag as 'changed' if appropriate
      */
    private function _prop_set(name:String, value:Dynamic):Dynamic {
        if (this.nativeArrayGet( name ) != value) {
            this.nativeArraySet(name, value);
            _changed = true;
        }
        return value;
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

/* === Instance Fields === */

    public var c:Null<Char>;
    public var fg:Null<Color>;
    public var bg:Null<Color>;
    public var bold:Null<Bool>;
    public var underline:Null<Bool>;
    public var invisible:Null<Bool>;
    
    public var nextCell(default, null): Null<Cell>;
    public var row(default, null): Null<CellRow<Cell>>;
    
    private var _changed:Bool = false;
}

typedef CellDecl = {?c:Char, ?fg:Color, ?bg:Color, ?bold:Bool, ?underline:Bool, ?invisible:Bool};
