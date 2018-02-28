package pman.ui.views;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.async.*;

import tannus.css.Value;
import tannus.css.vals.*;

import gryffin.core.*;
import gryffin.display.*;

import haxe.extern.EitherType as Either;
import haxe.ds.Vector;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.ui.views.CharacterMatrixViewMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;

using tannus.css.vals.ValueTools;

@:allow( pman.ui.views.CharacterMatrixViewAccessor )
class CharacterMatrixViewStyle {
    /* Constructor Function */
    public function new(?bg:Color, ?text:Either<CharacterMatrixViewTextStyleDecl, CharacterMatrixViewTextStyle>):Void {
        backgroundColor = bg;
        if ((text is CharacterMatrixViewTextStyle)) {
            this.text = cast text;
        }
        else {
            var text:CharacterMatrixViewTextStyleDecl = nullOr(text, {});
            this.text = new CharacterMatrixViewTextStyle(text.font, text.color, text.decoration);
        }

        changed = true;
    }

/* === Instance Methods === */

    public inline function clone():CharacterMatrixViewStyle {
        return new CharacterMatrixViewStyle(backgroundColor.clone(), text.clone());
    }

    private inline function setChanged(isChanged: Bool):Bool {
        return (changed = isChanged);
    }

    private inline function resetChanged():Bool return setChanged( false );
    private inline function announceChanged():Bool return setChanged( true );
    private inline function touch():Bool return announceChanged();

    public inline function setForegroundColor(v: Color):Void {
        deltaSet(text.color, v, touch(), (_1 != null && _1.equals( _2 )));
    }
    public inline function setBackgroundColor(v: Color):Void {
        deltaSet(backgroundColor, v, touch(), (_1 != null && _1.equals( _2 )));
    }

    public inline function setFontSize(v: Float):Void {
        deltaSet(font.size.value, v, touch());
    }

    public inline function setFontSizeUnit(v: String):Void {
        deltaSet(font.size.unit, v, touch());
    }

    public inline function setFontFamily(v: String):Void {
        deltaSet(font.family, v, touch());
    }

    public inline function setBold(v: Bool):Void {
        deltaSet(decoration.bold, v, touch());
    }

    public inline function setItalic(v: Bool):Void {
        deltaSet(decoration.italic, v, touch());
    }

    public inline function setUnderline(v: Bool):Void {
        deltaSet(decoration.underline, v, touch());
    }

    public inline function setTextDecoration(?bold:Bool, ?italic:Bool, ?underline:Bool):Void {
        if (bold != null)
            setBold( bold );

        if (italic != null)
            setItalic( italic );

        if (underline != null)
            setUnderline( underline );
    }

    public inline function setFont(?family:String, ?size:Float, ?unit:String):Void {
        qm(family, setFontFamily(_));
        qm(size, setFontSize(_));
        qm(unit, setFontSizeUnit(_));
    }

    public inline function setParent(parent: Null<CharacterMatrixViewStyle>):Void {
        this.parent = parent;
    }

    public function applyOther(o: CharacterMatrixViewStyle):Void {
        qm(o.backgroundColor, setBackgroundColor(_));
        qm(o.text.color, setForegroundColor(_));
        qm(o.text.font.family, setFontFamily(_));
        qm(o.text.font.size.value, setFontSize(_));
        qm(o.text.font.size.unit, setFontSizeUnit(_));
        qm(o.text.decoration.bold, setBold(_));
        qm(o.text.decoration.italic, setItalic(_));
        qm(o.text.decoration.underline, setUnderline(_));
    }

    private static function resolve<T>(ctx:Either<Array<CharacterMatrixViewStyle>, CharacterMatrixViewStyle>, f:CharacterMatrixViewStyle->Null<T>):Null<T> {
        var i: Iterator<CharacterMatrixViewStyle>;
        if ((ctx is Array<CharacterMatrixViewStyle>)) {
            i = (ctx : Array<CharacterMatrixViewStyle>).iterator();
        }
        else {
            var ctx:CharacterMatrixViewStyle = (ctx : CharacterMatrixViewStyle);
            i = {
                hasNext: function():Bool return (ctx.parent != null),
                next: function():CharacterMatrixViewStyle return (ctx = ctx.parent)
            };
        }

        var style: CharacterMatrixViewStyle;
        var result;
        while (i.hasNext()) {
            style = i.next();
            result = f( style );
            if (result != null) {
                return result;
            }
        }
        return null;
    }

    public static function _resolveFullStyle(style: CharacterMatrixViewStyle):CharacterMatrixViewStyle {
        var result:CharacterMatrixViewStyle = new CharacterMatrixViewStyle();
        result.setForegroundColor(resolve(style, x->x.foregroundColor));
        result.setFontSize(resolve(style, x->x.fontSize));
        result.setFontSizeUnit(resolve(style, x->x.fontSizeUnit));
        result.setFontFamily(resolve(style, x->x.fontFamily));
        result.setBold(resolve(style, x->x.bold));
        result.setItalic(resolve(style, x->x.italic));
        result.setUnderline(resolve(style, x->x.underline));
        return result;
    }

    public static inline function _null():CharacterMatrixViewStyle return new CharacterMatrixViewStyle();

    public static function decl(o: CharacterMatrixViewStyleDecl):CharacterMatrixViewStyle {
        return new CharacterMatrixViewStyle(o.backgroundColor, o.text);
    }
    public static function mdecl(x: Either<CharacterMatrixViewStyle, CharacterMatrixViewStyleDecl>):CharacterMatrixViewStyle {
        if ((x is CharacterMatrixViewStyle)) {
            return cast x;
        }
        else {
            return decl(cast x);
        }
    }

/* === Computed Instance Fields === */

    public var foregroundColor(get, never): Null<Color>;
    private inline function get_foregroundColor() return text.color;

    public var font(get, never): CharacterMatrixViewTextStyleFont;
    private inline function get_font() return text.font;

    public var fontSize(get, never): Null<Float>;
    private inline function get_fontSize() return font.size.value;

    public var fontSizeUnit(get, never): Null<String>;
    private inline function get_fontSizeUnit() return font.size.unit;

    public var fontFamily(get, never): Null<String>;
    private inline function get_fontFamily() return font.family;

    public var decoration(get, never): CharacterMatrixViewTextStyleDecoration;
    private inline function get_decoration() return text.decoration;

    public var bold(get, never): Null<Bool>;
    private inline function get_bold() return decoration.bold;
    
    public var italic(get, never): Null<Bool>;
    private inline function get_italic() return decoration.italic;

    public var underline(get, never): Null<Bool>;
    private inline function get_underline() return decoration.underline;

/* === Instance Fields === */

    public var backgroundColor(default, null): Null<Color>;
    public var text(default, null): CharacterMatrixViewTextStyle;

    public var changed(default, null): Bool;

    public var parent(default, null): Null<CharacterMatrixViewStyle>;
}

/*
   class used to hold text-related styling information
*/
@:allow( pman.ui.views.CharacterMatrixViewStyle )
class CharacterMatrixViewTextStyle {
    /* Constructor Function */
    public function new(?font:Either<CharacterMatrixViewTextStyleFont, CharacterMatrixViewTextStyleFontDecl>, ?color:Either<String, Color>, ?decor:Either<CharacterMatrixViewTextStyleDecorationDecl,CharacterMatrixViewTextStyleDecoration>):Void {
        // resolve [color] property
        if (color == null) {
            this.color = null;
        }
        else if ((color is String)) {
            this.color = Color.fromString(cast color);
        }
        else {
            this.color = untyped color;
        }

        // = resolve [font] property
        if (font == null)
            font = untyped {size: {}};

        if ((font is CharacterMatrixViewTextStyleFont)) {
            this.font = (font : CharacterMatrixViewTextStyleFont);
        }
        else {
            var font:Dynamic = (font : Dynamic);
            this.font = new CharacterMatrixViewTextStyleFont(font.family, font.size, font.size.unit);
        }

        if (decor == null)
            decor = {};

        var dec:Dynamic = (decor : Dynamic);
        this.decoration = new CharacterMatrixViewTextStyleDecoration(dec.bold, dec.italic, dec.underline);
    }

/* === Instance Methods === */

    /**
      * create and return a deep-copy of [this]
      */
    public inline function clone():CharacterMatrixViewTextStyle {
        return new CharacterMatrixViewTextStyle(font.clone(), color.clone(), decoration.clone());
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var font(default, null): CharacterMatrixViewTextStyleFont;
    public var decoration(default, null): CharacterMatrixViewTextStyleDecoration;

    public var color(default, null): Color;
}

@:allow( pman.ui.views.CharacterMatrixViewStyle )
class CharacterMatrixViewTextStyleFont {
    /* Constructor Function */
    public function new(?family:String, ?size:Float, ?sizeUnit:String):Void {
        this.family = family;
        this.size = {
            value: size,
            unit: sizeUnit
        };
    }

/* === Instance Methods === */

    public inline function clone():CharacterMatrixViewTextStyleFont {
        return new CharacterMatrixViewTextStyleFont(family, size.value, size.unit);
    }

/* === Instance Fields === */

    public var family(default, null): Null<String>;
    public var size(default, null): CharacterMatrixViewTextStyleFontSize;
}

@:allow( pman.ui.views.CharacterMatrixViewStyle )
class CharacterMatrixViewTextStyleDecoration {
    /* Constructor Function */
    public inline function new(?bold:Bool, ?italic:Bool, ?underline:Bool):Void {
        this.bold = bold;
        this.italic = italic;
        this.underline = underline;
    }

/* === Instance Methods === */

    /**
      * create and return a deep-copy of [this]
      */
    public inline function clone():CharacterMatrixViewTextStyleDecoration {
        return new CharacterMatrixViewTextStyleDecoration(bold, italic, underline);
    }

/* === Instance Fields === */

    public var bold(default, null): Null<Bool>;
    public var italic(default, null): Null<Bool>;
    public var underline(default, null): Null<Bool>;
}


typedef CharacterMatrixViewTextStyleFontSize = {
    ?value: Float,
    ?unit: String
};

typedef CharacterMatrixViewTextStyleDecl = {
    ?font: Either<CharacterMatrixViewTextStyleFont, CharacterMatrixViewTextStyleFontDecl>,
    ?color: Either<String, Color>,
    ?decoration: CharacterMatrixViewTextStyleDecorationDecl
};

typedef CharacterMatrixViewTextStyleDecorationDecl = {
    ?bold: Bool,
    ?italic: Bool,
    ?underline: Bool
};

typedef CharacterMatrixViewTextStyleFontDecl = {
    ?family: String,
    ?size: Either<Float, CharacterMatrixViewTextStyleFontSizeDecl>
};

typedef CharacterMatrixViewTextStyleFontSizeDecl = {
    ?value: Float,
    ?unit: String
};

typedef CharacterMatrixViewStyleDecl = {
    ?backgroundColor: Color,
    ?text: Either<CharacterMatrixViewTextStyleDecl, CharacterMatrixViewTextStyle>
};
