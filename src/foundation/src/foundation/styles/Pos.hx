package foundation.styles;

@:forward
abstract Pos (TPos) from TPos {
	/* Constructor Function */
	public inline function new(o : TPos):Void {
		this = o;
	}

	public var type(get, set):PosType;
	private inline function get_type():PosType return (o.type != null ? o.type : Initial);
	private inline function set_type(v : PosType):PosType return (o.type = v);

	/*
	public var top(get, set):Int;
	private inline function get_top():Int return (o.top != null ? o.top : 0);
	private inline function set_top(v : Int):Int return (o.top = v);

	public var left(get, set):Int;
	private inline function get_left():Int return (o.left != null ? o.left : 0);
	private inline function set_left(v : Int):Int return (o.left = v);

	public var bottom(get, set):Int;
	private inline function get_bottom():Int return (o.bottom != null ? o.bottom : 0);
	private inline function set_bottom(v : Int):Int return (o.bottom = v);

	public var right(get, set):Int;
	private inline function get_right():Int return (o.right != null ? o.right : 0);
	private inline function set_right(v : Int):Int return (o.right = v);
	*/

	private var o(get, never):TPos;
	private inline function get_o():TPos return this;
}

@:enum
abstract PosType (String) from String to String {
	var Absolute = 'absolute';
	var Fixed = 'fixed';
	var Inherit = 'inherit';
	var Initial = 'initial';
	var Relative = 'relative';
	var Static = 'static';
}

typedef TPos = {
	?type : PosType,
	?top : Int,
	?left : Int,
	?bottom : Int,
	?right : Int
};
