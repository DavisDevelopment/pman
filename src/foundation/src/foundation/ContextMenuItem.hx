package foundation;

import tannus.io.Signal;
import tannus.events.*;

import Std.*;
import Std.is in istype;
import Math.*;
import tannus.math.TMath.*;
import tannus.internal.TypeTools;
import tannus.internal.CompileTime in Ct;
import foundation.Tools.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
//using foundation.Tools;

class ContextMenuItem extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		menu = null;
		clickEvent = new Signal();

		build();
	}

/* === Instance Methods === */

	/**
	  * build the content of [this]
	  */
	override private function populate():Void {
		super.populate();

		addClass( 'context-menu-item' );
		textSpan = new Span( 'Menu Button' );
		append( textSpan );

		forwardEvents(['click'], null, MouseEvent.fromJqEvent);
		on('click', click.bind());
	}

	/**
	  * respond to the click event
	  */
	public function click(event : MouseEvent):Void {
		clickEvent.call( event );
	}

/* === Computed Instance Fields === */

	override private function get_text():String return textSpan.text;
	override private function set_text(v : String):String return (textSpan.text = v);

/* === Instance Fields === */

	public var textSpan : Span;
	public var menu : Null<ContextMenu>;

	public var clickEvent : Signal<MouseEvent>;
}
