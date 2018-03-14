package pman.ui.views.curses;

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

import gryffin.core.*;
import gryffin.display.*;

import pman.ds.FixedLengthArray as FlArray;
import pman.core.Ent;
import pman.ui.views.curses.models.*;

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
    }

/* === Instance Methods === */

    /**
      * initialize [this] view
      */
    override function init(stage: Stage):Void {
        super.init( stage );

        calculateCharMetrics();
    }

    /**
      * update [this] view
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        //TODO
    }

    /**
      * render [this] view
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        if (grid.hasChangedStyles()) {
            //TODO
        }
        else if (grid.hasChanged()) {
            //TODO
        }

        c.drawComponent(canvas, 0, 0, canvas.width, canvas.height, x, y, w, h);
    }

    /**
      * calculate [this]'s total geometry
      */
    override function calculateGeometry(r: Rect<Float>):Void {
        if (charMetrics == null) {
            return ;
        }
        else {
            w = (charMetrics.width * grid.width);
            h = (charMetrics.height * grid.height);
        }
    }

    /**
      * calculate the global character metrics
      */
    private function calculateCharMetrics():Area<Int> {
        // all chars except the whitespace
        var line:String = allChars.slice(0, -4);
        var letter:String = 'A';

        //ctx.font = '${fontStyle.size.value}${fontStyle.size.unit} ${fontStyle.family}';
        ctx.font = '${grid.fontSize}${grid.fontSizeUnit} ${grid.fontFamily}';
        ctx.textAlign = 'start';
        ctx.textBaseline = 'top';

        var letterMetrics = ctx.measureText( letter );
        var lineMetrics = ctx.measureText( line );

        charMetrics = new Area(round( letterMetrics.width ), round( lineMetrics.height ));

        return charMetrics;
    }

    /**
     * get the string for the font style
     */
    private function fontString(?cell: TCell):String {
        var chunks:Array<String> = new Array();
        if (nullOr(cell.bold, grid.bold))  {
            chunks.push( 'bold' );
        }
        chunks.push('${grid.fontSize}${grid.fontSizeUnit}');
        chunks.push( grid.fontFamily );
        return chunks.join(' ');
    }

    /**
      * apply the necessary styling to the given rendering context
      */
    private function applyStyles(c:Ctx, ?cell:TCell):Void {
        c.font = fontString( cell );
        c.textAlign = 'start';
        c.textBaseline = 'top';
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

/* === Static Vars === */

    /* a String containing all valid characters */
    private static var allChars: String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-=[]{}\\|;:\'\"<>,./?\t\n\r ';
}
