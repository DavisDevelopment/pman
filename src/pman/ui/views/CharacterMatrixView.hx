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

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.ui.views.CharacterMatrixViewMacros.*;
import pman.GlobalMacros.nullOr;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;
using tannus.FunctionTools;

@:allow( pman.views.CharacterMatrixViewAccessor )
class CharacterMatrixView {
    /* Constructor Function */
    public function new(?options: CharacterMatrixViewOptions):Void {
        canvas = null;
        width = 0;
        height = 0;

        charMetrics = null;
        style = new CharacterMatrixViewStyle(new Color(255, 255, 255), cast {
            color: new Color(0, 0, 0),
            font: ({
                family: 'UbuntuMono',
                size: {
                    value: 10.0,
                    unit: 'pt'
                }
            } : Dynamic)
        });

        // parse [options]
        if (options == null) {
            options = {
                width: 100,
                height: 100,
                foregroundColor: new Color(0, 0, 0),
                backgroundColor: new Color(255, 255, 255)
            };
        }

        _parseOptions( options );

        // initialize [this]
        if (options.autoBuild == null || !options.autoBuild) {
            init();
        }
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    public inline function init():Void {
        if (canvas == null) {
            canvas = Canvas.create(width, height);
        }

        calculateCharMetrics();
        buildBuffer();

        cursor = buffer.cursor;
    }

    /**
      * attach a view to [this]
      */
    public function attachRenderer(r: CharacterMatrixViewRenderer):Void {
        renderer = r;
    }

    /**
      * update [this] in it's entirety
      */
    public function repaint():Void {
        var start = now();
        update( true );
        var took = (now() - start);
        trace('a full repaint of CharacterMatrix[$height][$width](${width * height} cells) took ${took}ms');
    }

    /**
      * update [this] CharacterMatrixView
      */
    public function update(all:Bool=false):Void {
        var canr:Rect<Int> = calculateCanvasRect();
        if (canvas.width != canr.width || canvas.height != canr.height) {
            canvas.resize(canr.width, canr.height);
            all = true;
        }
        
        if (all || isChanged()) {
            var y:Int = 0;
            var line:CharacterMatrixViewBufferLine;
            var cell:CharacterMatrixViewBufferLineChar;
            for (y in 0...height) {
                line = buffer.lines[y];
                var x:Int = 0;
                if (all || line.isChanged()) {
                    for (x in 0...width) {
                        cell = line.col( x );
                        if (cell == null) {
                            throw 'Error: CharacterMatrixViewBufferLineChar not found';
                        }
                        else if (all || cell.changed) {
                            updateCell( cell );
                            cell.untouch();
                        }
                    }
                }
                line.untouch();
            }
        }
        buffer.untouch();
    }

    /**
      * update a particular cell, betty
      */
    public function updateCell(cell: CharacterMatrixViewBufferLineChar):Void {
        // get reference to the canvas rendering context
        var c:Ctx = canvas.context;

        // get a reference to the relevant style object
        var ls:CharacterMatrixViewStyle = (cell.style != null ? cell.style : style);

        // apply styling object to the drawing properties
        _applyStyles(c, cell.style);

        // calculate the cell's content rectangle
        var cr:Rect<Int> = calculateCharCellRect( cell );

        // draw the cell's background
        c.fillRect(cr.x, cr.y, cr.width, cr.height);

        // set the text color
        c.fillStyle = nullOr(ls.foregroundColor, style.foregroundColor);

        // if [cell] has a character to be drawn at all
        if (cell.char != null) {
            // draw the text
            c.fillText(cell.char, cr.x, cr.y, cr.width);
        }
    }

    /**
      * apply [this]'s styles onto [canvas]
      */
    private inline function _applyStyles(c:Ctx, ?cellStyle:CharacterMatrixViewStyle):Void {
        var ls:CharacterMatrixViewStyle = (cellStyle != null ? cellStyle : style);

        c.font = fontString( cellStyle );
        c.textAlign = 'start';
        c.textBaseline = 'top';
        c.fillStyle = nullOr(ls.backgroundColor, style.backgroundColor, new Color(255, 255, 255));
    }

    /**
      * get the string for the font style
      */
    private function fontString(?cellStyle:CharacterMatrixViewStyle):String {
        var chunks:Array<String> = new Array();
        var ls:CharacterMatrixViewStyle = (cellStyle != null ? cellStyle : style);
        if (nullOr(ls.bold, false))  {
            chunks.push('bold');
        }
        else if (nullOr(ls.italic, false)) {
            chunks.push('italic');
        }
        chunks.push('${style.fontSize}${style.fontSizeUnit}');
        chunks.push(nullOr(style.fontFamily, 'UbuntuMono'));
        return chunks.join(' ');
    }

    /**
      * calculate the global character metrics
      */
    private function calculateCharMetrics():Area<Int> {
        // all chars except the whitespace
        var line:String = allChars.slice(0, -4);
        var letter:String = 'A';

        //ctx.font = '${fontStyle.size.value}${fontStyle.size.unit} ${fontStyle.family}';
        ctx.font = '${style.font.size.value}${style.font.size.unit} ${style.font.family}';
        ctx.textAlign = 'start';
        ctx.textBaseline = 'top';

        var letterMetrics = ctx.measureText( letter );
        var lineMetrics = ctx.measureText( line );

        charMetrics = new Area(round( letterMetrics.width ), round( lineMetrics.height ));

        return charMetrics;
    }

    /**
      * calculate the Rect<Int> for a single cell
      */
    public inline function calculateCharCellRect(cell: CharacterMatrixViewBufferLineChar):Rect<Int> {
        return charMetrics.with(new Rect(
            (cell.x * _.width),
            (cell.line.y * _.height),
            (_.width),
            (_.height)
        ));
    }

    /**
      * 
      */
    public inline function calculateCanvasRect():Rect<Int> {
        return new Rect(0, 0, ceil(charMetrics.width) * width, ceil(charMetrics.height) * height);
    }

    /**
      * calculate maximum size allowed by the given viewport rect
      */
    public function calculateSize(viewport: Rect<Int>):Void {
        calculateCharMetrics();
        width = floor(viewport.width / charMetrics.width);
        height = floor(viewport.height / charMetrics.height);
    }

    /**
      * build out the content buffer
      */
    private inline function buildBuffer():Void {
        buffer = new CharacterMatrixViewBuffer( this );
    }

    /**
      * check if [this] view is changed
      */
    public inline function isChanged():Bool {
        return (changed || buffer.isChanged());
    }

    public inline function applyStyles(os: CharacterMatrixViewStyle):Void {
        style.applyOther( os );
        touch();
    }

    /**
      * parse out [options]
      */
    private function _parseOptions(o : CharacterMatrixViewOptions):Void {
        nullSet(width, o.width);
        nullSet(height, o.height);

        if (o.dimensions != null) {
            width = o.dimensions.width;
            height = o.dimensions.height;
        }

        if (o.rect != null) {
            width = o.rect.width;
            height = o.rect.height;
        }

        if (o.font != null) {
            if ((o.font is String)) {
                //TODO
            }
            else if (Reflect.isObject( o.font )) {
                // get a reference to the fontObject
                var fo = (o.font : {family:String, ?size:{value:Float,?unit:String}});

                // set the font-family
                style.setFontFamily( fo.family );

                // handle [fo.size]
                if (fo.size != null) {
                    style.setFontSize( fo.size.value );
                    qm(fo.size.unit, style.setFontSizeUnit(_));
                }
            }
            else {
                throw 'TypeError: Invalid value for options.font';
            }
        }

        qm(o.fontFamily, style.setFontFamily(_));
        qm(o.fontSize, style.setFontSize(_));
        qm(o.fontSizeUnit, style.setFontSizeUnit(_));



        qm(o.foregroundColor, style.setForegroundColor(_color(_)));
        qm(o.backgroundColor, style.setBackgroundColor(_color(_)));

        defer(applyStyles.bind(style.clone()));
    }

    /**
      * get character metrics
      */
    public inline function getCharMetrics():Null<Area<Int>> {
        return charMetrics;
    }

    /**
      * assign the value of [changed]
      */
    public inline function setChanged(v: Bool):Bool {
        return (changed = v);
    }

    /**
      * flag [this] as having changed
      */
    public inline function touch():Void setChanged( true );

    /**
      * remove 'changed' flag
      */
    public inline function untouch():Void setChanged( false );

    /**
      * get a Color instance from either a String or an existing Color instance
      */
    private static function _color(x: Either<String, Color>):Color {
        if ((x is String)) {
            return Color.fromString(cast x);
        }
        else {
            return untyped x;
        }
    }

    /**
      * sanitize a y-coordinate value
      */
    public function sanitize_y(y: Int):Int {
        if (!y.inRange(0, height)) {
            outOfBounds(y, 0, height);
        }
        return y;
    }

    /**
      * sanitize an x-coordinate value
      */
    public function sanitize_x(x: Int):Int {
        if (!x.inRange(0, width)) {
            outOfBounds(x, 0, width);
        }
        return x;
    }
      * raise an IndexOutOfBounds exception
      */
    private static function outOfBounds(v:Int, ?boundMin:Int, ?boundMax:Int):Void {
        throw (if (boundMin != null && boundMax != null) {
            CharacterMatrixError.EIndexOutOfBounds(v, new IntRange(boundMin, boundMax));
        }
        else {
            CharacterMatrixError.EIndexOutOfBounds( v );
        });
    }

/* === Computed Instance Fields === */

    private var ctx(get, never):Ctx;
    private inline function get_ctx() return canvas.context;

/* === Static Variables === */

    /* a String containing all valid characters */
    private static var allChars: String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-=[]{}\\|;:\'\"<>,./?\t\n\r ';

/* === Instance Fields === */

    public var canvas: Null<Canvas>;
    public var buffer: CharacterMatrixViewBuffer;
    public var cursor: CharacterMatrixViewBufferCursor;
    public var width(default, null): Int;
    public var height(default, null): Int;

    public var style(default, null): CharacterMatrixViewStyle;
    public var renderer(default, null): Null<CharacterMatrixViewRenderer> = null;
    //public var foregroundColor(default, null): Color;
    //public var backgroundColor(default, null): Color;

    //public var fontStyle(default, null): CharacterMatrixViewFontStyle;

    private var charMetrics: Null<Area<Int>>;
    private var changed: Bool = false;
}

typedef CharacterMatrixViewOptions = {
    ?canvas: Canvas,
    ?width: Int,
    ?height: Int,
    ?dimensions: Rect<Int>,
    ?rect: Rect<Int>,

    ?font: Either<String, {family: String, ?size: {value: Float, ?unit: String}}>,
    ?fontFamily: String,
    ?fontSize: Either<String, Float>,
    ?fontSizeUnit: String,
    ?foregroundColor: Either<String, Color>,
    ?backgroundColor: Either<String, Color>,
    ?autoBuild: Bool
};

enum CharacterMatrixError {
    EIndexOutOfBounds(index:Int, ?bounds:IntRange);
    ENamed(errorName:String, ?errorData:Dynamic);
    ECoded(errorCode:Int, ?errorData:Dynamic);
}
