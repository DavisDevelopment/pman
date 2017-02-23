package foundation;

import foundation.Button;
import foundation.List;

import Std.*;

using Lambda;
using tannus.ds.ArrayTools;

class ButtonGroup extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'button-group' );

		buttons = new Array();
	}

/* === Instance Methods === */

	/**
	  * Attach an Object to [this]
	  */
	override private function _attach(child:Dynamic, attacher:Widget.Attacher):Void {
		super._attach(child, attacher);
		if (Std.is(child, Button)) {
			buttons.push(cast child);
		}
	}

	/*
	   "class switch"
	   @param [name]
	   @type String
	 */
	private inline function cs(n:String, v:Bool=true):Bool {
		(v ? addClass : removeClass)( n );
		return is( '.$n' );
	}

	/* enable/disable the 'tiny' size-mod */
	public inline function tiny(?v : Bool):Bool return cs('tiny', v);
	public inline function small(?v : Bool):Bool return cs('small', v);
	public inline function large(?v : Bool):Bool return cs('large', v);
	public inline function expand(?v : Bool):Bool return cs('expanded', v);

/* === Instance Fields === */

	public var buttons : Array<Button>;
}
