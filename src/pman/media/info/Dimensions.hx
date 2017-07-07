package pman.media.info;

@:structInit
class Dimensions {
    public var w : Int;
    public var h : Int;
    public inline function new(w:Int, h:Int) {
        this.w = w;
        this.h = h;
    }

    public inline function equals(o : Dimensions):Bool {
        return (w == o.w && h == o.h);
    }

    public function toString():String {
        return '${w}x${h}';
    }
}
