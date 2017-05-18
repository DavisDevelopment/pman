package pman.events;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;
import tannus.events.Key;

import pman.events.*;
import pman.events.KeyboardEventDescriptor as Ked;
import pman.events.KeyboardEventType as Ket;

import Std.*;
import tannus.math.TMath.*;
import Reflect.compareMethods;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class KbInputHandler {
    /* Constructor Function */
    public function new(descriptor : Ked):Void {
        d = descriptor;
        h = new Array();
    }

/* === Instance Methods === */

    public function on(f : KeyboardEvent->Void):Void {
        add(HTOn( f ));
    }

    public function once(f : KeyboardEvent->Void):Void {
        add(HTOnce( f ));
    }

    public function off(f : KeyboardEvent->Void):Void {
        h = h.filter(function(t : HandlerType) {
            switch ( t ) {
                case HTOn(func), HTOnce(func):
                    return !compareMethods(f, func);

                default:
                    return true;
            }
        });
    }

    public function emit(event : KeyboardEvent):Void {
        for (type in h) {
            if ( !event.propogationStopped ) {
                callHandler(type, event);
            }
        }
    }

    /**
      * check whether the given method is attached to [this] as a listener
      */
    public function hasHandler(f : KeyboardEvent->Void):Bool {
        for (type in h) {
            switch ( type ) {
                case HTOn(lf), HTOnce(lf):
                    if (compareMethods(f, lf)) {
                        return true;
                    }
            }
        }
        return false;
    }

    /**
      * get the number of listeners
      */
    public inline function handlerCount():Int return h.length;
    public inline function hasAnyHandlers():Bool return (handlerCount() > 0);
    public inline function empty():Bool return !hasAnyHandlers();

    private function callHandler(type:HandlerType, event:KeyboardEvent):Void {
        switch ( type ) {
            case HTOn( action ):
                action( event );

            case HTOnce( action ):
                action( event );
                off( action );
        }
    }

    // add a HandlerType
    private inline function add(t : HandlerType):Void {
        h.push( t );
    }

/* === Instance Fields === */

    public var d(default, null):Ked;

    private var h:Array<HandlerType>;
}

private enum HandlerType {
    HTOn(f : KeyboardEvent->Void);
    HTOnce(f : KeyboardEvent->Void);
}
