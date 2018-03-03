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
    }
}
