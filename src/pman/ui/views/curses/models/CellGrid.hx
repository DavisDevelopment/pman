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

import pman.ds.FixedLengthArray as FlArray;
import pman.ui.views.curses.models.Cell;

import Std.*;
import tannus.math.TMath.*;
#if !eval
import edis.Globals.*;
import pman.ui.views.CharacterMatrixViewMacros.*;
#end

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

class CellGrid <TCell:Cell, TRow:CellRow<TCell>> extends EventDispatcher {
    /* Constructor Function */
    public function new(w:Int, h:Int):Void {
        super();

        width = w;
        height = h;
        firstRow = null;
        rows = FlArray.alloc( height );
        _updated = false;
        _updatedStyle = false;
        _updatedRows = new Array();

        fg = new Color(0, 0, 0);
        bg = new Color(255, 255, 255);
        bold = false;
        underline = false;
        fontFamily = 'monospace';
        fontSize = 10.0;
        fontSizeUnit = 'pt';

        inline function prop(name:String) {
            defineSetter(name, setStyleProperty.bind(name, _));
        }

        prop( 'fg' );
        prop( 'bg' );
        prop( 'bold' );
        prop( 'underline' );
        prop( 'fontFamily' );
        prop( 'fontSize' );
        prop( 'fontSizeUnit' );

        _build();
    }

/* === Instance Methods === */

    /**
      * get the row at [y]
      */
    public function getRow(y: Int):Null<TRow> {
        return rows[y];
    }

    /**
      * get the cell at [y, x]
      */
    public function getCell(y:Int, x:Int):Null<TCell> {
        return rows[y].getCell( x );
    }

    /**
      * resize [this] grid
      */
    public function resize(w:Int, h:Int):Void {
        if (h != height) {
            var _h:Int = height;
            height = h;

            if (height > _h) {
                var _rows = rows;
                rows = FlArray.alloc( height );
                for (i in 0..._h) {
                    rows[i] = _rows[i];
                    rows[i].grid = cast this;

                    if (i == 0) {
                        firstRow = rows[i];
                    }
                    else {
                        rows[i - 1].nextRow = cast rows[i];
                    }
                }
                for (i in 0...(height - _h)) {
                    rows[height + i] = _buildRow();
                    rows[height + i].grid = cast this;
                }
            }
            else {
                rows = rows.slice(0, height);
                for (row in rows) {
                    row.grid = cast this;
                }
            }
        }

        if (w != width) {
            var _w:Int = width;
            width = w;

            for (row in rows) {
                row.resize( width );
            }
        }
    }

    /**
      * build out the list of rows
      */
    private function _build():Void {
        for (i in 0...height) {
            rows[i] = _buildRow();
            rows[i].grid = cast this;

            if (i == 0) {
                firstRow = rows[i];
            }
            else {
                rows[i - 1].nextRow = cast rows[i];
            }
        }
    }

    /**
      * build and return a row
      */
    private function _buildRow():TRow {
        return cast new CellRow( width );
    }

    /**
      * flag [row] as updated
      */
    public function alt(?row:TRow, all:Bool=false):Void {
        if ( all ) {
            for (row in rows) {
                if (!_updatedRows.has( row )) {
                    _updatedRows.push( row );
                }
            }
        }
        else {
            if (!_updatedRows.has( row )) {
                _updatedRows.push( row );
            }
        }
        _updated = _updatedRows.hasContent();
    }

    /**
      * repair the linked-list structure
      */
    public function _repairRowListLinking():Void {
        for (i in 0...height) {
            rows[i].nextRow = null;
            if (i == 0) {
                firstRow = rows[i];
            }
            else {
                rows[i - 1].nextRow = cast rows[i];
            }
        }
    }

    /**
      * style-property setter
      */
    private function setStyleProperty<T>(property:String, newValue:T):T {
        var val:Null<T> = this.nativeArrayGet( property );
        if (val != newValue) {
            _updatedStyle = true;
        }
        return nativeArraySet(property, newValue);
    }

    /**
      * check whether [this] Grid has been updated
      */
    public function hasChanged():Bool return _updated;

    /**
      * check whether [this]'s styles have been changed
      */
    public function hasChangedStyles():Bool return _updatedStyle;

    /**
      * get the list of updated rows
      */
    public function getChangedRows():Array<TRow> return _updatedRows;

/* === Instance Fields === */

    public var width(default, null): Int;
    public var height(default, null): Int;
    public var firstRow(default, null): Null<TRow>;
    public var rows(default, null): FlArray<TRow>;
    //public var style: GridStyleDecl;

    /* == Style Fields == */
    public var fg: Color;
    public var bg: Color;
    public var bold: Bool;
    public var underline: Bool;
    public var fontFamily: String;
    public var fontSize: Float;
    public var fontSizeUnit: String;

    private var _updated: Bool;
    private var _updatedStyle: Bool;
    private var _updatedRows: Array<TRow>;
}

typedef GridStyleDecl = {
    ?fg: Color,
    ?bg: Color,
    ?bold: Bool,
    ?underline: Bool,
    ?fontFamily: String,
    ?fontSize: Float,
    ?fontSizeUnit: String
};
