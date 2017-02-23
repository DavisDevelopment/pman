package foundation;

import foundation.Pane;

import tannus.ds.*;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

class FlexPane extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();
		addClass( 'columns' );
		_columnManager = new FlexColumnSizing( this );
	}

/* === Instance Methods === */

	/* get column-count */
	public inline function getColumns(?n:String):Null<Int> return columns.getSize( n );

	/* set column count */
	public inline function setColumns(c:Null<Int>, ?n:String):Null<Int> return columns.setSize(c, n);

/* === Instance Fields === */

	public var columns(get, never):FlexColumnSizing;
	private inline function get_columns():FlexColumnSizing return _columnManager;

	private var _columnManager : FlexColumnSizing;
}

class FlexColumnSizing {
	/* Constructor Function */
	public function new(p : FlexPane):Void {
		pane = p;
		breakpoints = new Dict();
		for (name in Foundation.mqBreakpoints) {
			breakpoints[name] = new FlexColumnSize(pane, name);
		}
	}

/* === Instance Methods === */

	/* get the FlexColumnSize for the given breakpoint */
	public inline function on(breakpoint : String):FlexColumnSize return breakpoints.get( breakpoint );

	/* get the current FlexColumnSize */
	public function sizeManager(?name : String):FlexColumnSize {
		if (name == null) name = Foundation.mq.current;
		return on( name );
	}

	/* get the size */
	public inline function getSize(?name : String):Null<Int> return sizeManager( name ).size;

	/* set the size */
	public inline function setSize(value:Null<Int>, ?name:String):Null<Int> return (sizeManager( name ).size = value);

/* === Instance Fields === */

	public var pane : FlexPane;
	public var breakpoints : Dict<String, FlexColumnSize>;
}

@:access( foundation.Widget )
@:allow( foundation.FlexRow )
class FlexColumnSize {
	/* Constructor Function */
	public function new(pan:FlexPane, nam:String):Void {
		pane = pan;
		name = nam;
	}

/* === Instance Methods === */

	/* set the value for [size] */
	public inline function is(value : Int):Int return (size = value);

/* === Computed Instance Fields === */

	/* the number of columns occupied */
	public var size(get, set):Null<Int>;
	private function get_size():Null<Int> {
		var scn = pane.classes().macfirstMatch(_.startsWith( '$name-' ));
		if (scn == null) {
			return null;
		}
		else {
			return parseInt(scn.after( '$name-' ));
		}
	}
	private function set_size(v : Null<Int>):Null<Int> {
		if (v == null) {
			for (c in pane.classes().macfilter(_.startsWith('$name-'))) {
				pane.removeClass( c );
			}
			return null;
		}
		else {
			var scn = pane.classes().macfirstMatch(_.startsWith( '$name-' ));
			pane.removeClass( scn );
			pane.addClass( '$name-$v' );
			return v;
		}
	}

	/* whether [pane] will shrink to only occupy the space that it's contents need */
	public var shrinks(get, set):Bool;
	private inline function get_shrinks():Bool {
		return pane.is( '.shrink' );
	}
	private function set_shrinks(v : Bool):Bool {
		if ( v ) {
			pane.addClass( 'shrink' );
		}
		else {
			pane.removeClass( 'shrink' );
		}
		return shrinks;
	}

	public var expand(get, set):Bool;
	private inline function get_expand():Bool return (size == null && !shrinks);
	private inline function set_expand(v : Bool):Bool {
		if ( v ) {
			size = null;
			return !(shrinks = false);
		}
		else {
			pane.classes().macfilter(_.endsWith( 'expand' )).each(pane.removeClass( _ ));
			return false;
		}
	};

/* === Instance Fields === */

	public var pane : FlexPane;
	public var name : String;
}
