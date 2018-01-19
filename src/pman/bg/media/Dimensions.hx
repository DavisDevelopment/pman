package pman.bg.media;

import tannus.ds.*;
import tannus.geom2.*;

import Reflect.compare as c;

class Dimensions implements tannus.ds.IComparable<Dimensions> {
    public inline function new(w:Int, h:Int) {
        this.w = w;
        this.h = h;
    }

    public inline function equals(o : Dimensions):Bool {
        return (w == o.w && h == o.h);
    }

    public function compareTo(o : Dimensions):Int {
        var x = c(w, o.w);
        if (x != 0)
            return x;
        else {
            x = c(h, o.h);
            return x;
        }
    }

    public function toArea():Area<Int> return new Area(w, h);

    public function toString():String {
        return '${w}x${h}';
    }

    public var w : Int;
    public var h : Int;
}
