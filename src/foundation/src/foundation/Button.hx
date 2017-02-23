package foundation;

import foundation.Widget;
import foundation.ButtonSize;

class Button extends Widget {
	/* Constructor Function */
	public function new(txt : String):Void {
		super();
		// el = '<a href="#" class="button">$txt</a>';
		el = d.createButtonElement();
		el.set('type', 'button');
		el.addClass( 'button' );
		el.text = txt;

		__init();
	}

/* === Instance Methods === */

	/**
	  * Initalize [this] Button
	  */
	private function __init():Void {
		el.on('click mouseenter mouseleave', function( event ) {
			dispatch(event.type, event);
		});
	}

	/**
	  * Reset [this] Button's size to 'normal'
	  */
	private function resetSize():Void {
		var all:Array<ButtonSize> = [Tiny, Small, Large, Fill];
		for (s in all)
			el.removeClass(s);
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

	public inline function secondary(?v : Bool):Bool return cs('secondary', v);
	public inline function success(?v : Bool):Bool return cs('success', v);
	public inline function warning(?v : Bool):Bool return cs('warning', v);
	public inline function alert(?v : Bool):Bool return cs('alert', v);
	public inline function disable(?v : Bool):Bool return cs('disabled', v);
	public inline function hollow(?v : Bool):Bool return cs('hollow', v);
}
