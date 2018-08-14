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
import haxe.ds.Option;

import pman.ds.FixedLengthArray as FlArray;
import pman.ui.views.curses.models.CellGrid;
import pman.ui.views.curses.models.CellRow;
import pman.ui.views.curses.models.Cell;

import Std.*;
import tannus.math.TMath.*;

using Slambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.ds.IteratorTools;
using tannus.ds.MapTools;
using tannus.ds.DictTools;
using tannus.async.Asyncs;
using tannus.async.OptionTools;

class CellGridContext {
    /* Constructor Function */
    public function new(grid) {
        //initialize variables
        this.grid = grid;
        cx = 0;
        cy = 0;
    }

/* === Instance Methods === */

    inline function moveTo(y:Int, x:Int) {
        cy = y;
        cx = x;
    }

    inline function move(y:Int, x:Int) {
        moveTo(cy + y, cx + x);
    }

    inline function row(?y:Int):CellRow<Cell> {
        return cast grid.getRow(sanitize_y(_y(y)));
    }

    inline function col(?y:Int, ?x:Int):Cell {
        return cast grid.getCell(sanitize_y(_y(y)), sanitize_x(_x(x)));
    }

    function adjust(?y:Int, ?x:Int):Pos {
        y = _y(y);
        x = _x(x);
        var i = (x + (y * grid.width));
        return new Pos(int(i % grid.width), int(i / grid.width));
    }

    function sanitize_x(x: Int):Int {
        if (!x.inRange(0, grid.width))
            throw EOutOfBounds(x, 0, grid.width);
        return x;
    }

    function sanitize_y(y: Int):Int {
        if (!y.inRange(0, grid.height))
            throw EOutOfBounds(y, 0, grid.height);
        return y;
    }

    inline function _y(?y: Int):Int return nullOr(y, cy);
    inline function _x(?x: Int):Int return nullOr(x, cx);
    inline function _index(?x:Int, ?y:Int):Int return (_x(x) + grid.width * _y(y));

/* === Computed Fields === */

    var ci(get, set): Int;
    inline function get_ci():Int return (cx + grid.width * cy);
    inline function set_ci(v: Int):Int {
        cx = (v % grid.width);
        cy = int(v / grid.width);
        return v;
    }

    var cp(get, set): Pos;
    inline function get_cp() return new Pos(cx, cy);
    inline function set_cp(v: Pos):Pos {
        cx = v.x;
        cy = v.y;
        return v;
    }

/* === Instance Fields === */

    public var grid(default, null): CellGrid<Cell, CellRow<Cell>>;
    public var cy(default, null): Int;
    public var cx(default, null): Int;

    var styles: CtxStyles;
}

abstract CtxStyles (TCStyles) from TCStyles {
    public inline function new() {
        this = new TCStyles(None, None, None, None);
    }

    public inline function clone():CtxStyles {
        return cast new TCStyles(obb, obu, oca, ocb);
    }

    public inline function set(b:Option<Bool>, u:Option<Bool>, fg:Option<Color>, bg:Option<Color>):CtxStyles {
        set_obb( b );
        set_obu( u );
        set_oca( fg );
        set_ocb( bg );
        return this;
    }

    public inline function clear():CtxStyles {
        return set(None, None, None, None);
    }

    public inline function empty():Bool {
        return (get(0).match(None) && get(1).match(None) && get(1).match(None));
    }

    @:to
    public function decl():CellDecl {
        return {fg:fg, bg:bg, bold:bold, underline:underline};
    }

    public var oca(get, set): Option<Color>;
    private inline function get_oca():Option<Color> return this._2;
    private inline function set_oca(v):Option<Color> return (this._2 = v);

    public var ocb(get, set): Option<Color>;
    private inline function get_ocb():Option<Color> return this._3;
    private inline function set_ocb(v):Option<Color> return (this._3 = v);

    public var obb(get, set): Option<Bool>;
    private inline function get_obb():Option<Bool> return this._0;
    private inline function set_obb(v):Option<Bool> return (this._0 = v);

    public var obu(get, set): Option<Bool>;
    private inline function get_obu():Option<Bool> return this._1;
    private inline function set_obu(v):Option<Bool> return (this._1 = v);

    public var fg(get, set): Null<Color>;
    private inline function get_fg():Null<Color> return oca.getValue();
    private inline function set_fg(v):Null<Color> return (v == null ? None : Some(v));

    public var bg(get, set): Null<Color>;
    private inline function get_bg():Null<Color> return ocb.getValue();
    private inline function set_bg(v):Null<Color> return (v == null ? None : Some(v));

    public var bold(get, set): Null<Bool>;
    private inline function get_bold():Null<Bool> return obb.getValue();
    private inline function set_bold(v):Null<Bool> return (v == null ? None : Some(v));

    public var underline(get, set): Null<Bool>;
    private inline function get_underline():Null<Bool> return obb.getValue();
    private inline function set_underline(v):Null<Bool> return (v == null ? None : Some(v));
}

typedef TCStyles = tannus.ds.tuples.Tup4<Option<Bool>, Option<Bool>, Option<Color>, Option<Color>>;

abstract Pos (Pair<Int, Int>) from Pair<Int, Int> from Array<Int> from Point<Int> {
    public inline function new(x:Int, y:Int) {
        this = new Pair(x, y);
    }

    @:from
    public static inline function fromArray(a: Array<Int>):Pos return new Pos(a[0], a[1]);

    @:from
    public static inline function fromPoint(p: Point<Int>):Pos return new Pos(p.x, p.y);

    public var x(get, never): Int;
    private function get_x():Int return this.left;

    public var y(get, never): Int;
    private function get_y():Int return this.right;
}
