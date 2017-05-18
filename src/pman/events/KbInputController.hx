package pman.events;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;
import tannus.events.Key;

import pman.events.*;
import pman.events.KeyboardEventDescriptor as Ked;
import pman.events.KeyboardEventType;
import pman.events.KeyboardEventType as Ket;

import Std.*;
import tannus.math.TMath.*;
import gryffin.Tools.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class KbInputController {
    /* Constructor Function */
    public function new():Void {
        type = PRESS;

        handlers = new Dict();
        anySignal = new Signal();
        interceptSignal = new Signal();
    }

/* === Instance Methods === */

    /**
      * register an event listener
      */
    public function on(descriptor:Ked, handler:KeyboardEvent->Void):Void {
        h( descriptor ).on( handler );
    }
    public function once(descriptor:Ked, handler:KeyboardEvent->Void):Void {
        h( descriptor ).once( handler );
    }
    public function anyOn(handler : KeyboardEvent->Void):Void {
        anySignal.on( handler );
    }
    public function anyOnce(handler : KeyboardEvent->Void):Void {
        anySignal.once( handler );
    }
    public function interceptNext(handler : KeyboardEvent->Void):Void {
        isi.once( handler );
    }
    public inline function inext(handler : KeyboardEvent->Void):Void interceptNext( handler );

    /**
      * intercept the next incoming event
      * if said event occurs more than [maxDelay] milliseconds after binding, `action(false)`
      * else if [check] returns false for said event, `action(true)`
      * else `action(true)`
      */
    public function inextWithin(check:KeyboardEvent->Bool, action:Bool->Void, maxDelay:Float=450):Void {
        function handler(event : KeyboardEvent):Void {
            isi.off( handler );
            action(check( event ));
        }
        inext( handler );
        wait(ceil( maxDelay ), function() {
            isi.off( handler );
            action( false );
        });
    }

    /**
      * deregister a listener
      */
    public function off(descriptor:Ked, handler:KeyboardEvent->Void):Void {
        if (handlers.exists( descriptor )) {
            var hh = handlers[descriptor];
            hh.off( handler );
            if (hh.empty()) {
                handlers.remove( descriptor );
            }
        }
    }
    public function anyOff(handler : KeyboardEvent->Void):Void {
        anySignal.off( handler );
    }

    /**
      * emit an event
      */
    public function emit(event : KeyboardEvent):Void {
        // build descriptor
        var eventDesc:Ked = Ked.fromEvent( event );

        // check that the descriptor isn't ignored
        if (ignoreModEvents && isMod( eventDesc )) {
            return ;
        }

        // if there are any intercept-listeners registered
        if (isi.hasListeners()) {
            isi.call( event );
            isi.clear();
            return ;
        }

        // broadcast to 'any' listeners
        anySignal.call( event );

        // if event was stifled by any listener
        if ( event.propogationStopped ) {
            return ;
        }

        // broadcast to handler for described event
        if (handlers.exists( eventDesc )) {
            handlers[eventDesc].emit( event );
        }
    }

    /**
      * get the handler associated with the given KeyboardEventDescriptor
      */
    public function handler(d : Ked):KbInputHandler {
        if (!handlers.exists( d )) {
            return handlers[d] = new KbInputHandler( d );
        }
        else {
            return handlers[d];
        }
    }
    private inline function h(d : Ked):KbInputHandler return handler( d );

    /**
      * test whether the given KeyboardEventDescriptor describes an event for a modifier key
      */
    public inline function isMod(d : Ked):Bool {
        return (
            (d.key == Key.Alt) ||
            (d.key == Key.Ctrl) ||
            (d.key == Key.Shift) ||
            (d.key == Key.Command)
        );
    }

/* === Computed Instance Fields === */

    private var isi(get, never):Signal<KeyboardEvent>;
    private inline function get_isi() return interceptSignal;

    private var asi(get, never):Signal<KeyboardEvent>;
    private inline function get_asi() return anySignal;

/* === Instance Fields === */

    public var type(default, null):KeyboardEventType;
    public var ignoreModEvents:Bool=true;

    private var handlers:Dict<Ked, KbInputHandler>;
    private var anySignal:Signal<KeyboardEvent>;
    private var interceptSignal:Signal<KeyboardEvent>;
}
