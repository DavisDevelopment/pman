package pman.ui.views;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.css.Value;
import tannus.css.vals.Lexer as CssValueTokenizer;

import gryffin.core.*;
import gryffin.display.*;

/*
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;
*/
import pman.core.*;

import haxe.extern.EitherType as Either;

import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.css.vals.ValueTools;

class TextBoxView extends Ent {
    /* Constructor Function */
    public function new(?opts: TextBoxOptions):Void {
        super();
        if (opts == null)
            opts = {};

        textBox = new TextBox();
        //textRect = new Rect();
    }

/* === Instance Methods === */

    override function init(stage: Stage):Void {
        super.init( stage );

        textBox.onStateChanged.on(function(mode: Int) {
            if (mode == 0) {
                recalc = true;
            }
        });
    }

    /**
      perform per-frame logic on [this]
     **/
    override function update(stage: Stage):Void {
        super.update( stage );

        if ( recalc ) {
            calculateGeometry(cast stage.rect);
        }
    }

    /**
      paint [this] view onto the canvas
     **/
    override function render(stage:Stage, c:Ctx):Void {
        if (!textBox.text.empty()) {
            c.drawComponent(textBox, 0, 0, textBox.width, textBox.height, floor(x), floor(y), round(w), round(h));
        }
    }

    /**
      calculate [this]'s content rect
     **/
    override function calculateGeometry(r: Rect<Float>):Void {
        w = textBox.width;
        h = textBox.height;

        recalc = false;
    }

    public function forceRedraw():TextBoxView {
        var tmp = textBox.text;
        setText(tmp.empty() ? '-' : null);
        setText( tmp );
        return this;
    }

    public function setText(txt: Null<String>):TextBoxView {
        if (txt == null)
            txt = '';
        textBox.text = txt;
        return this;
    }

    public function setTextStyle(font:Either<String, FontFaceOpts>, ?color:Color):TextBoxView {
        var ffo = getFontFace( font );

        nullSet(textBox.fontFamily, ffo.family);
        nullSet(textBox.fontSize, ffo.size.v);
        nullSet(textBox.fontSizeUnit, ffo.size.u);
        nullSet(textBox.bold, ffo.bold);
        nullSet(textBox.italic, ffo.italic);

        nullSet(textBox.color, color);

        return this;
    }

    function getFontFace(font: Either<String, FontFaceOpts>):FontFaceDec {
        var fontFace: FontFaceDec;
        if ((font is String)) {
            fontFace = untyped {
                {size: {v:0,u:null}};
            };
            var ffsize = (fontFace.size : {v:Float,?u:String});

            var values = CssValueTokenizer.parseString(cast font);
            switch ( values ) {
                case [VIdent(x), VIdent(y), VNumber(v, u), VIdent(n)|VString(n)]:
                    cssv_id(x, fontFace);
                    cssv_id(y, fontFace);
                    ffsize.v = v;
                    ffsize.u = u;
                    fontFace.family = n;

                case [VIdent(x), VNumber(v, u), VIdent(n)|VString(n)]:
                    cssv_id(x, fontFace);
                    ffsize.v = v;
                    ffsize.u = u;
                    fontFace.family = n;

                case [VNumber(v, u), VIdent(n)|VString(n)]:
                    ffsize.v = v;
                    ffsize.u = u;
                    fontFace.family = n;
                
                case [VIdent(n) | VString(n)]:
                    fontFace.family = n;

                case [VIdent(n) | VString(n), VNumber(v, u)]:
                    fontFace.family = n;
                    ffsize.v = v;
                    ffsize.u = u;

                case _:
                    report("Error: Unhandled ${values}");
            }
        }
        else {
            fontFace = cast font;
        }
        return fontFace;
    }

    function cssv_id(s:String, o:FontFaceOpts) {
        switch (s.toLowerCase()) {
            case 'italic':
                o.italic = true;

            case 'bold':
                o.bold = true;

            case _:
                throw 'Unexpected "$s"';
        }
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var textBox: TextBox;
    //public var textRect: Rect<Float>;

    var recalc:Bool = false;
}

typedef TextBoxOptions = {
    ?fontFamily: String,
    ?fontSize: Float,
    ?fontSizeUnit: String,
    ?bold: Bool,
    ?italic: Bool
};

typedef FontFaceOpts = {
    ?family: String,
    ?size: Either<String, {v:Float, ?u:String}>,
    ?bold: Bool,
    ?italic: Bool
};
typedef FontFaceDec = {
    ?family: String,
    ?size: {v:Float, ?u:String},
    ?bold: Bool,
    ?italic: Bool
};
