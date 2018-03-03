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

import pman.ui.views.CharacterMatrixViewStyle;

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
using tannus.ds.IteratorTools;

class CharacterMatrixState {}

class CharCellTools {
    /**
      * get the 'state' of the given cell
      */
    public static function getCharState(c: CharacterMatrixViewBufferLineChar):CharCellState {
        var ms:Maybe<CharacterMatrixViewStyle> = c.style;
        return {
            a: {
                b: ms.ternary(_.backgroundColor, null),
                f: ms.ternary(_.foregroundColor, null)
            },
            b: {
                b: ms.ternary(_.bold, null),
                u: ms.ternary(_.underline, null)
            },
            c: c.char
        };
    }

    /**
      * apply the given 'state' to the given cell
      */
    public static function applyCharState(state:CharCellState, c:CharacterMatrixViewBufferLineChar):Void {
        if (c.style == null)
            c.style = new CharacterMatrixViewStyle();
        if (state.a.b != null)
            c.style.setBackgroundColor( state.a.b );
        if (state.a.f != null)
            c.style.setForegroundColor( state.a.f );
        if (state.b.b != null)
            c.style.setBold( state.b.b );
        if (state.b.u != null)
            c.style.setUnderline( state.b.u );
        c.setChar( state.c );
    }
}

typedef CharCellState = {
    a: {?b: Color, ?f: Color},
    b: {?b:Bool, ?u:Bool},
    c: Null<Char>
};
