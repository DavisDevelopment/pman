package pman.events;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.Key;

import js.html.KeyboardEvent as NativeKbEvent;
import js.jquery.Event as JqEvent;

import haxe.extern.EitherType;

using Slambda;
using tannus.FunctionTools;

class KeyboardEvent extends ModSensitiveEvent {
    /* Constructor Function */
    public function new(type:String, keyCode:Int, target:Dynamic, ?evt:Dynamic):Void {
        super();

        this.type = type;
        originalTarget = this.target = target;
        e = evt;
        previousKeyboardEvent = null;
        key = this.keyCode = keyCode;
    }

/* === Instance Methods === */

    override function preventDefault() {
        super.preventDefault();
        if (e != null) {
            untyped {e.preventDefault();}
        }
    }

    @:noCompletion
    public function _setMods(alt:Bool, ctrl:Bool, meta:Bool, shift:Bool) {
        altKey = alt;
        ctrlKey = ctrl;
        metaKey = meta;
        shiftKey = shift;
    }

    public function _setPrevious(event: KeyboardEvent) {
        this.previousKeyboardEvent = event;
    }

    public static function fromNative(e: NativeKbEvent):KeyboardEvent {
        var res = new KeyboardEvent(e.type, e.keyCode, e.target);
        res._setMods(e.altKey, e.ctrlKey, e.metaKey, e.shiftKey);
        return res;
    }

    public static function fromJqEvent(e: JqEvent):KeyboardEvent {
        var res = new KeyboardEvent(e.type, e.keyCode, e.target);
        res._setMods(e.altKey, e.ctrlKey, e.metaKey, e.shiftKey);
        return res;
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var keyCode: Int;
    public var key: Key;
    public var previousKeyboardEvent(default, null): Null<KeyboardEvent>;
    
    var e:Null<EitherType<NativeKbEvent, JqEvent>>;
}
