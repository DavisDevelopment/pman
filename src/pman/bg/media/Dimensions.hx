package pman.bg.media;

import tannus.ds.*;
import tannus.geom2.*;
import tannus.math.Percent;

import Reflect.compare as c;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.ds.AnonTools;
using tannus.FunctionTools;
using tannus.math.TMath;

@:forward
abstract Dimensions (CDimensions) from CDimensions to CDimensions {
    public inline function new(w:Int, h:Int) {
        this = new CDimensions(w, h);
    }

    @:op(A == B)
    public inline function equals(d: Dimensions):Bool return this.equals( d );

    @:op(A / B)
    public inline function relative(s: String):Dimensions {
        return parseString(s, this);
    }

    @:op(A * B)
    public static inline function relativeTo(s:String, d:Dimensions):Dimensions {
        return d.relative( s );
    }

    @:to
    public inline function toArea():Area<Int> return new Area(this.w, this.h);
    @:to
    public inline function toTuple():tannus.ds.tuples.Tup2<Int, Int> return new tannus.ds.tuples.Tup2(this.w, this.h);
    @:to
    public inline function toArray():Array<Int> return [this.w, this.h];
    @:to
    public inline function toString():String return this.toString();

    /**
      betty
     **/
    private static function parseAsRect(s:String, ?relTo:Rect<Float>):Rect<Float> {
        if (s.has('x')) {
            var vec = [s.before('x'), s.after('x')];
            switch vec {
                case [x, y] if (x.isNumeric() && y.isNumeric()):
                    var nvec = vec.map(Std.parseFloat);
                    if (nvec.all(n -> (!n.isNaN() && n.isFinite() && n > 0))) {
                        return new Rect(0.0, 0.0, nvec[0], nvec[1]);
                    }
                    else {
                        throw 'TypeError: (${nvec[0]})x(${nvec[1]}) is not a valid rectangle';
                    }

                case ['?', y] if (y.isNumeric() && relTo != null):
                    return relTo.scaled(null, Std.parseFloat( y ));

                case [x, '?'] if (x.isNumeric() && relTo != null):
                    return relTo.scaled(Std.parseFloat( x ), null);

                case [_, '?'],['?', _] if (relTo == null):
                    throw 'Error: Cannot use relative-size syntax without supplying a base size';

                default:
                    throw 'WTBF';
            }
        }
        else if (percre.match(s.trim())) {
            var numSub:String = (percre.matched(0).ifEmpty(percre.matched(1)));
            if (numSub.empty())
                throw 'Wut duh hael';
            var perc:Percent = new Percent(Std.parseFloat(numSub));
            return relTo.scaled(perc.of(1.0), perc.of(1.0));
        }
        else {
            throw 'WTBF';
        }
    }
    private static var percre:EReg = ~/^(?:([\d.]+)%)|(?:perc(?:ent)?\(([\d.]+)\))$/gmi;

    public static inline function parseString(s:String, ?relTo:Dimensions):Dimensions {
        return fromRect(cast parseAsRect(s, (relTo != null ? new Rect(0.0, 0.0, relTo.w, relTo.h) : null)).floor());
    }
    @:from
    public static inline function fromString(s: String):Dimensions {
        return parseString(s, null);
    }

    @:from
    public static inline function fromRect(r: Rect<Float>):Dimensions {
        return new Dimensions(Std.int(r.width), Std.int(r.height));
    }
}

class CDimensions implements tannus.ds.IComparable<Dimensions> {
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
