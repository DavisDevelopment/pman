package pman.events;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;
import tannus.events.Key;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

@:structInit
class KeyboardEventDescriptor implements IComparable<KeyboardEventDescriptor> {
    /* Constructor Function */
    public function new(key:Key, alt:Bool=false, ctrl:Bool=false, shift:Bool=false, meta:Bool=false):Void {
        this.key = key;
        this.alt = alt;
        this.ctrl = ctrl;
        this.shift = shift;
        this.meta = meta;
    }

/* === Instance Methods === */

    /**
      * validate [e] against [this]
      */
    public inline function test(e : KeyboardEvent):Bool {
        return (
            (key == e.key) &&
            (alt == e.altKey) &&
            (ctrl == e.ctrlKey) &&
            (shift == e.shiftKey) &&
            (meta == e.metaKey)
        );
    }

    /**
      * clone [this]
      */
    public inline function clone():KeyboardEventDescriptor {
        return new KeyboardEventDescriptor(key, alt, ctrl, shift, meta);
    }

    /**
      * compare to other
      */
    public function compareTo(o : KeyboardEventDescriptor):Int {
        return Reflect.compare(btext(), o.btext());
    }

    /**
      * 
      */
    public function btext():String {
        inline function bc(x : Bool) return (x ? '1' : '0');
        var bits:Array<String> = [string(key).lpad('0', 4)];
        bits = bits.concat(mods().map.fn(bc(_)));
        return bits.join( ',' );
    }

    /**
      * get array of modifier values
      */
    public inline function mods():Array<Bool> {
        return [alt, ctrl, shift, meta];
    }

/* === Instance Fields === */

    public var key : Key;

    public var alt : Bool;
    public var ctrl : Bool;
    public var shift : Bool;
    public var meta : Bool;

    public static function fromEvent(e : KeyboardEvent):KeyboardEventDescriptor {
        return new KeyboardEventDescriptor(e.key, e.altKey, e.ctrlKey, e.shiftKey, e.metaKey);
    }
}
