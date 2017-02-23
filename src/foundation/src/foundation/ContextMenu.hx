package foundation;

import Std.*;
import Std.is in istype;
import Math.*;
import tannus.math.TMath.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.internal.TypeTools;
import tannus.internal.CompileTime in Ct;
import tannus.html.Element;
import tannus.html.Win;
import tannus.css.vals.Lexer;
import tannus.css.Value in CSSValue;
import tannus.css.Value;
import foundation.Tools.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
using tannus.css.vals.ValueTools;
//using foundation.Tools;

class ContextMenu extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'context-menu' );
		buttons = new Array();

		build();
	}

/* === Instance Methods === */

	/**
	  * if [this] has not been added to the body, add it now
	  */
	private function _eadd():Void {
		if (!childOf( 'body' )) {
			appendTo( 'body' );
		}
	}

	/**
	  * Open [this] Context menu
	  */
	public function open(?target : Point):Void {
		if (co != null) {
			co.close();
		}

		_eadd();
		css['display'] = 'block';
		
		if (target != null) {
			var mr = place( target );
			trace( mr );
		}
		else {
			pos([0, 0]);
		}

		ensureOnTop();
		co = this;
	}

	/**
	  * Close [this] menu
	  */
	public function close():Void {
		destroy();
		co = null;
	}

	/**
	  * Add an item to [this]
	  */
	public function addItem(item : ContextMenuItem):ContextMenuItem {
		append( item );
		return item;
	}

	/**
	  * Create, append, and return a new Item
	  */
	public function item(text:String, ?onclick:ContextMenuItem->Void):ContextMenuItem {
		var i = new ContextMenuItem();
		i.text = text;
		if (onclick != null) {
			i.clickEvent.on(function(e) onclick( i ));
		}
		addItem( i );
		return i;
	}

	/**
	  * append something to [this]
	  */
	override private function _attachWidget(child:Widget, attacher:Widget.Attacher):Void {
		super._attachWidget(child, attacher);

		if (istype(child, ContextMenuItem)) {
			var cmi:ContextMenuItem = cast child;
			cmi.menu = this;
			if (!buttons.has( cmi )) {
				buttons.push( cmi );
			}
		}
	}

	/**
	  * using the given target-rectangle, determine the most optimal position for [this] menu
	  */
	public function place(pos : Point):Rectangle {
		var vp = win.viewport;
		var mr:Rectangle = rect();
		var rl = [for (i in 0...4) mr.clone()];

		rl[0].topLeft = pos;
		rl[1].topRight = pos;
		rl[2].bottomLeft = pos;
		rl[3].bottomRight = pos;
		
		var fit:Null<Rectangle> = null;

		for (r in rl) {
			if (vp.containsRect( r )) {
				fit = r;
				break;
			}
		}

		var res:Rectangle = rect();
		if (fit != null) {
			res = rect( fit );
		}
		return res;
	}

	private inline function gcp_values(name : String):Array<CSSValue> {
		return gcp( name ).ternary(tannus.css.vals.Lexer.parseString(_), new Array());
	}

	private function ensureOnTop():Void {
		var all:Element = '*';
		for (e in all.toArray()) {
			if (e.at(0) == el.at(0)) {
				continue;
			}
			var sz = e.css( 'z-index' );
			if (sz == null || sz == '') {
				continue;
			}
			else if (Std.parseInt(e.css( 'z-index' )) > Std.int(el.z)) {
				el.z = (Std.parseInt(e.css( 'z-index' )) + 5);
			}
		}
	}

/* === Computed Instance Fields === */

	private var win(get, never):Win;
	private inline function get_win():Win return Win.current;

/* === Instance Fields === */

	private var buttons : Array<ContextMenuItem>;

/* === Static Fields === */

	/* currently open */
	private static var co : Null<ContextMenu> = null;
}
