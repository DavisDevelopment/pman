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

class CellRow <T:Cell> extends EventDispatcher {
    /* Constructor Function */
    public function new(len: Int):Void {
        super();

        // [= Properties =]
        d = null;
        length = len;
        index = null;
        firstCell = null;
        nextRow = null;
        _updated = false;
        _updatedAll = false;
        _updatedCells = new Array();
        grid = null;

        // [= EVENTS =]
        addSignals([
            'resize',
            'reposition',
            'preprocess',
            'process:diff',
            'process:commit',
            'process:push',
            'reconcile'
        ]);

        _build();
    }

/* === Instance Methods === */

    /**
      * get the cell at [x]
      */
    public function getCell(x: Int):Null<T> {
        return d[x];
    }

    /**
      * write data onto the cell at [x]
      */
    public function setCell(x:Int, cell:Either<T, CellDecl>):Void {
        getCell( x ).write(cast cell);
    }

    /**
      * reassign the size [length] of [this] row
      */
    public function resize(newSize: Int):Void {
        if (length != newSize) {
            var oldSize = length;
            length = newSize;
            _rebuild();
            once('reconcile', (e)->dispatch('resize', new Delta(newSize, oldSize)));
        }
    }

    /**
      * build out the structure of [this] Row
      */
    private function _build():Void {
        d = FlArray.alloc( length );
        
        for (x in 0...length) {
            d[x] = _createCell();
            d[x].row = cast this;

            if (x == 0) {
                firstCell = d[x];
            }
            else {
                d[x - 1].nextCell = d[x];
            }
        }

        alt( true );
    }

    /**
      * build out the structure of [this] Row, following some change that requires it to built again
      */
    private function _rebuild():Void {
        var _d = d;
        if (length != _d.length) {
            if (length < _d.length) {
                set_d(_d.slice(0, length));
                alt( true );
            }
            else {
                var addend:Int = (length - _d.length);
                var nd = FlArray.alloc( length );
                nd.blit(_d, 0, 0, _d.length);
                for (i in 0...addend) {
                    var nc = nd[_d.length + i] = _createCell();
                    alt( nc );
                    nc.row = cast this;

                    if (_d.length == 0) {
                        firstCell = nc;
                    }
                    else {
                        nd[_d.length + i - 1].nextCell = nc;
                    }
                }
                set_d( nd );
            }
        }
        else {
            _build();
        }
    }

    /**
      * repair the linked-list structure after some action that made changed [d] but did not synchronize 
      * the linked-list structure with that change
      */
    public function _repairCellListLinking():Void {
        for (i in d.indices()) {
            d[i].nextCell = null;
            if (i == 0) {
                firstCell = d[i];
            }
            else {
                d[i - 1].nextCell = d[i];
            }
        }
    }

    /**
      * oh, yai
      */
    private function set_d(nd: FlArray<T>) {
        this.d = nd;
        this.length = this.d.length;
    }

    /**
      * create a new [Cell] instance to be attached to [this] Row
      */
    private function _createCell():T {
        return cast new Cell();
    }

    /**
      * announce that some unspecified change has been made to 
      * [this] structure that will necessitate some renderer or grid-level processing event
      */
    private function alt(?cell:T, ?all:Bool):Void {
        _updated = true;
        if (all != null) {
            _updatedAll = all;
        }
        if (cell != null && !_updatedAll) {
            if (!_updatedCells.has( cell )) {
                _updatedCells.push( cell );
            }
        }
    }

    /**
      * called by the grid once updates have been made to the
      * view in response to changes made to the model (#MvcFtw)
      */
    private function reconcile():Void {
        _updated = false;
        var uc = (_updatedAll ? d.array() : _updatedCells);
        _updatedAll = false;
        _updatedCells = [];
        dispatch('reconcile', {
            cells: uc
        });
    }

/* === Instance Fields === */

    public var length(default, null): Int;
    public var index(default, null): Null<Int>;
    public var firstCell(default, null): Null<T>;
    public var nextRow: Null<CellRow<Cell>>;
    public var d(default, null): FlArray<T>;
    public var grid:Null<CellGrid<Cell, CellRow<Cell>>>;

    private var _updated: Bool;
    private var _updatedAll: Bool;
    private var _updatedCells: Array<T>;
}
