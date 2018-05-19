package pman.ui.views.curses;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.internal.CompileTime as Ct;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.ds.Vector;
import haxe.macro.Expr;

import gryffin.core.*;
import gryffin.display.*;

import pman.ds.FixedLengthArray as FlArray;
import pman.core.Ent;
import pman.ui.views.curses.models.*;
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

/*
   base-class used to render cell-grids
*/
class CellGridView <TCell:Cell, TRow:CellRow<TCell>, TGrid:CellGrid<TCell, TRow>> extends Entity {
    /* Constructor Function */
    public function new(grid: TGrid):Void {
        super();

        this.grid = grid;
        this.canvas = new Canvas();
        this.priority = -10;
        this.rect = new Rect();

        _reports = new Array();
    }

/* === Instance Methods === */

    /**
      * initialize [this] view
      */
    override function init(stage: Stage):Void {
        super.init( stage );

        calculateCharMetrics();
        calculateGeometry(cast rect);
    }

    /**
      * update [this] view
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        // performance stuff
        _cyclePerfInfo();

        // calculate cell metrics
        if (charMetrics == null || grid.hasChangedStyles()) {
            calculateCharMetrics();
        }

        // calculate content area
        if (grid.hasChanged()) {
            calculateGeometry(cast rect);
        }
        
        // performance stuff
        if (_reportStartTime == null) {
            _startPerfReport();
        }
        else if ((now() - _reportStartTime) >= 1000) {
            _cyclePerfReport();
        }
    }

    /**
      * render [this] view
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if (grid.hasChangedStyles()) {
            //TODO

            grid.reconcileStyles();
        }
        
        if (grid.hasChanged()) {
            //TODO

            _paint();
            grid.reconcile();
        }
        else if ( needsRepaint ) {
            _paint( true );

            needsRepaint = false;
        }

        c.drawComponent(canvas, 0, 0, canvas.width, canvas.height, x, y, w, h);
    }

    /**
      check whether [p] is inside of [this]'s content rectangle
     **/
    override function containsPoint(p: Point<Float>):Bool {
        return rect.containsPoint( p );
    }

    /**
      * calculate [this]'s total geometry
      */
    override function calculateGeometry(r: Rect<Float>):Void {
        var d = [w, h];

        if (charMetrics == null) {
            return ;
        }
        else {
            w = (charMetrics.width * grid.width);
            h = (charMetrics.height * grid.height);
        }

        if (w != d[0] || h != d[1]) {
            canvas.resize(w, h);

            needsRepaint = true;
        }
    }

    /**
      * calculate the global character metrics
      */
    private function calculateCharMetrics():Area<Int> {
        // all chars except the whitespace
        var line:String = allChars.slice(0, -4);
        var letter:String = 'A';

        ctx.font = '${grid.fontSize}${grid.fontSizeUnit} ${grid.fontFamily}';
        ctx.textAlign = 'start';
        ctx.textBaseline = 'top';

        var letterMetrics = ctx.measureText( letter );
        var lineMetrics = ctx.measureText( line );

        charMetrics = new Area(round( letterMetrics.width ), round( lineMetrics.height ));

        return charMetrics;
    }

    /**
      paint [grid] onto [canvas]
     **/
    private function _paint(all:Bool = false):Void {
        /* define variables */
        var c:Ctx = ctx;
        var rows:Array<TRow> = all ? fla(grid.rows) : grid.getChangedRows();
        if (rows.empty()) return ;
        var cells:Array<TCell>, cr:Rect<Int>, cs:CellStyleDecl;

        var totalPaintTime:Float = _timef(function() {
            // for each row
            for (row in rows) {
                // get cells that need redrawing
                cells = all ? fla(row.getCells()) : row.getChangedCells();

                // for each cell that needs redrawing
                for (cell in cells) {
                    prtime(_timef(function() {
                        // get [cell]'s rectangle
                        cr = cellRect( cell );

                        // get [cell]'s styling
                        cs = cell.getStyleState();

                        /* draw the background */
                        c.fillStyle = cs.bg;
                        c.fillRect(cr.x, cr.y, cr.w, cr.h);

                        // if [cell] is not flagged as invisible, and has a non-whitespace character
                        if (!cell.invisible && cell.c != null) {
                            // apply (font) styling
                            applyStyles(c, cell);

                            // draw the character
                            c.fillText(cell.c, cr.x, cr.y, cr.width);
                            trace('drew char');
                        }

                        // announce update
                        prupdate();
                    }));
                }
            }
        });

        trace('repaint took ${totalPaintTime}ms');
    }
    private static inline function fla<T>(a: FlArray<T>):Array<T> {
        return a.toArray();
    }

    /**
      get the Rect<Int> corresponding with the given Cell
     **/
    private function cellRect(cell: TCell):Rect<Int> {
        var pos = cellKey( cell ), cm = charMetrics;
        return new Rect(
            (cm.width * pos[0]),
            (cm.height * pos[1]),
            cm.width,
            cm.height
        );
    }

    /**
      get [x, y] pair of indices for the given cell
     **/
    private inline function cellKey(cell: TCell):Array<Int> {
        return [cell.index, cell.row.index];
    }

    /**
     * get the string for the font style
     */
    private function fontString(?cell:TCell, ?state:CellStyleDecl):String {
        var chunks:Array<String> = new Array();
        inline function add(s) {
            chunks.push( s );
        }

        state = styleDecl(cell, state);

        if (nullOr(state.bold, false))  {
            add('bold ');
        }

        add('' + grid.fontSize);
        add( grid.fontSizeUnit );
        add(' ');
        add( grid.fontFamily );
        return chunks.join('');
    }

    /**
      * apply the necessary styling to the given rendering context
      */
    private function applyStyles(c:Ctx, ?cell:TCell, ?state:CellStyleDecl):Void {
        state = styleDecl(cell, state);
        
        c.font = fontString(cell, state);
        c.textAlign = 'start';
        c.textBaseline = 'top';
        c.fillStyle = state.fg;
    }

    private function styleDecl(?cell:TCell, ?style:CellStyleDecl):CellStyleDecl {
        if (style == null) {
            if (cell != null) {
                style = cell.getStyleState();
            }
            else {
                style = gridCellStyleDecl();
            }
        }
        return style;
    }
    private function gridCellStyleDecl():CellStyleDecl {
        return {
            fg: grid.fg,
            bg: grid.bg,
            bold: grid.bold,
            underline: grid.underline,
        };
    }

    private function _cyclePerfInfo() {
        if (_perfInfo != null) {
            _perfInfo.avg_time = _perfInfo.times.average();
            _currentReportData.add( _perfInfo );
        }
        _perfInfo = {
            updates: 0,
            times: [],
            avg_time: 0.0
        };
    }
    private inline function prupdate() _perfInfo.updates++;
    private inline function prtime(n: Float) _perfInfo.times.push( n );

    private function _startPerfReport() {
        _reportStartTime = now();
        _currentReportData = new List();
    }

    private function _cyclePerfReport() {
        if (_currentReportData != null) {
            var report = _perfReport();
            if (report == null) {
                return ;
            }

            if (_reports.length >= 30) {
                _reports.shift();
            }
            _reports.push( report );
        }
        _startPerfReport();
    }

    private function _perfReport():Null<PerfReport> {
        if (_currentReportData != null) {
            var report:PerfReport = {
                updates: 0,
                avg_update_time: 0
            };
            var avgs = [];
            for (x in _currentReportData) {
                report.updates += x.updates;
                avgs.push( x.avg_time );
            }
            report.avg_update_time = avgs.average();
            return report;
        }
        return null;
    }

    /**
      measure how long it takes [f] to execute
     **/
    private static inline function _timef(f: Void->Void):Float {
        var start:Float = now();
        f();
        return (now() - start);
    }

/* === Computed Instance Fields === */

    public var ctx(get, never):Ctx;
    private inline function get_ctx() return canvas.context;

	/* the 'x' position of [this] */
	public var x(get, set):Int;
	private inline function get_x():Int return rect.x;
	private inline function set_x(v : Int):Int return (rect.x = v);
	
	/* the 'y' position of [this] */
	public var y(get, set):Int;
	private inline function get_y():Int return rect.y;
	private inline function set_y(v : Int):Int return (rect.y = v);
	
	/* the width of [this] */
	public var w(get, set):Int;
	private function get_w():Int return rect.w;
	private function set_w(v : Int):Int return (rect.w = v);
	
	/* the height of [this] */
	public var h(get, set):Int;
	private function get_h():Int return rect.h;
	private function set_h(v : Int):Int return (rect.h = v);

/* === Instance Fields === */

    public var grid: TGrid;
    public var canvas: Canvas;
    public var charMetrics: Null<Area<Int>>;

    public var rect: Rect<Int>;

    private var needsRepaint: Bool = true;

    /* == Performance Properties == */
    private var _reportStartTime: Null<Float> = null;
    private var _currentReportData: List<PerfInfo>;
    private var _perfInfo: PerfInfo;
    private var _reports: Array<PerfReport>;

/* === Static Vars === */

    /* a String containing all valid characters */
    private static var allChars: String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-=[]{}\\|;:\'\"<>,./?\t\n\r ';
}

/**
  used to store performance info
 **/
private typedef PerfReport = {
    var updates: Int;
    var avg_update_time: Float;
}

private typedef PerfInfo = {
    // Cell updates
    var updates: Int;
    var times: Array<Float>;
    var avg_time: Float;
};

