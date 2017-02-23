package foundation;

import Std.*;
import Std.is in istype;
import tannus.math.TMath.*;
import tannus.internal.TypeTools;
import tannus.internal.CompileTime in Ct;
#if !macro
import tannus.html.Win;
import js.html.Console;
#end

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using haxe.macro.ExprTools;
using tannus.macro.MacroTools;

class Tools {
	/**
	  * defer the given Function until the end of the current Stack
	  */
	public static inline function defer(action : Void->Void):Void {
		win.requestAnimationFrame(untyped action);
	}

	/**
	  * macro-licious defer
	  */
	public static macro function macdefer(action : Expr) {
		action = action.buildFunction([], true);
		trace(action.toString());
		return macro foundation.Tools.defer( $action );
	}

	/* log error to console */
	public static inline function printError(err : Dynamic):Void c.error( err );
	public static inline function printObject(o : Dynamic):Void c.dir( o );
	public static inline function printTabular(o : Dynamic):Void c.table( o );

/* === Static Fields === */

#if !macro

	public static var win(get, never):Win;
	private static inline function get_win():Win return Win.current;

	public static var console(get, never):Console;
	private static inline function get_console():Console return win.console;

	private static var c(get, never):Console;
	private static inline function get_c():Console return win.console;

#else
	public static var win : Dynamic = null;
	public static var console : Dynamic = null;
	public static var c : Dynamic = null;
#end
}
