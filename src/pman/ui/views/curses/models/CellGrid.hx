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

/**
  class modelling a grid of cells
 **/
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

        // style properties
        style = {
            fg: new Color(0, 0, 0),
            bg: new Color(255, 255, 255),
            bold: false,
            underline: false,
            fontFamily: 'monospace',
            fontSize: 10.0,
            fontSizeUnit: 'pt'
        };
        _initStyleProperties();

        //fg = new Color(0, 0, 0);
        //bg = new Color(255, 255, 255);
        //bold = false;
        //underline = false;
        //fontFamily = 'monospace';
        //fontSize = 10.0;
        //fontSizeUnit = 'pt';

        // setter stuff
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
            rows[i].index = i;

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
      set [this]'s state such that no changes are flagged
     **/
    public function reconcile():Void {
        for (row in _updatedRows) {
            row.reconcile();
        }
        _updatedRows = [];
        _updated = false;
    }

    /**
      set [this]'s state such that no changes are flagged to styles
     **/
    public function reconcileStyles():Void {
        _updatedStyle = false;
    }

    /**
      repair the list-linking of the rows
     **/
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
      set the value of a property of [style]
     **/
    private function setStyleProperty<T>(property:String, newValue:T):T {
        var val:Null<T> = getStyleProperty( property );
        if (val != newValue) {
            _updatedStyle = true;
        }
        return style.nativeArraySet(property, newValue);
    }

    /**
      get the value of a property of [style]
     **/
    private function getStyleProperty<T>(property: String):Null<T> {
        return style.nativeArrayGet( property );
    }

    /**
      extend [this] to have all the properties that [style] has, and point those properties to [style]
     **/
    private function _initStyleProperties():Void {
        var props:Array<String> = 'bg,fg,bold,underline,fontFamily,fontSize,fontSizeUnit'.split(',');
        for (prop in props) {
            defineProperty(prop, {
                get: getStyleProperty.bind(prop),
                set: setStyleProperty.bind(prop, _)
            });
        }
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

    /* the number of cells per row */
    public var width(default, null): Int;

    /* the number of rows */
    public var height(default, null): Int;

    /* reference to the first row */
    public var firstRow(default, null): Null<TRow>;

    /* the array of rows */
    public var rows(default, null): FlArray<TRow>;

    /* == Style Fields == */
    public var fg: Color;
    public var bg: Color;
    public var bold: Bool;
    public var underline: Bool;
    public var fontFamily: String;
    public var fontSize: Float;
    public var fontSizeUnit: String;
    private var style: GridStyle;

    /* == State Fields == */

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

typedef GridStyle = {
    fg: Color,
    bg: Color,
    bold: Bool,
    underline: Bool,
    fontFamily: String,
    fontSize: Float,
    fontSizeUnit: String
};
