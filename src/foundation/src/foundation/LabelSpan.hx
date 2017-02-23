package foundation;

import tannus.html.Element;

using StringTools;

class LabelSpan extends Widget {
	/* Constructor Function */
	public function new():Void {
		super();

		el = '<span></span>';
		addClass( 'label' );
	}

/* === Instance Methods === */

	/*
	   "class switch"
	   @param [name]
	   @type String
	 */
	private inline function cs(n:String, v:Bool=true):Bool {
		(v ? addClass : removeClass)( n );
		return is( '.$n' );
	}

	public inline function secondary(?v : Bool):Void cs('secondary', v);
	public inline function success(?v : Bool):Void cs('success', v);
	public inline function alert(?v : Bool):Void cs('alter', v);
	public inline function warning(?v : Bool):Void cs('warning', v);

/* === Computed Instance Fields === */
/* === Instance Fields === */

}
