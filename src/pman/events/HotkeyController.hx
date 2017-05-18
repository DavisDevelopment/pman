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

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class HotkeyController {
    /* Constructor Function */
    public function new():Void {
        inputControllers = {
            down: new KbInputController(),
            up: new KbInputController(),
            press: new KbInputController()
        };
    }

/* === Instance Methods === */

    /**
      * emit a KeyboardEvent
      */
    public function emit(event : KeyboardEvent):Void {
        // get the controller
        var c = inputController( event.type );
        if (c != null) {
            c.emit( event );
        }
        else {
            throw 'Error: Unrecognized keyboard-event type "${event.type}"';
        }
    }

    /**
      * bind event handlers
      */
    public function on(type:KeyboardEventType, desc:KeyboardEventDescriptor, handler:KeyboardEvent->Void):Void {
        inputController( type ).on(desc, handler);
    }
    public function once(type:KeyboardEventType, desc:KeyboardEventDescriptor, handler:KeyboardEvent->Void):Void {
        inputController( type ).once(desc, handler);
    }

    /**
      * unbind event handlers
      */
    public function off(type:KeyboardEventType, desc:KeyboardEventDescriptor, handler:KeyboardEvent->Void):Void {
        inputController( type ).off(desc, handler);
    }

    /**
      * get an inputController by type
      */
    public function inputController(type : KeyboardEventType):Null<KbInputController> {
        return switch ( type ) {
            case DOWN: inputControllers.down;
            case UP: inputControllers.up;
            case PRESS: inputControllers.press;
        };
    }
    private inline function ic(t : KeyboardEventType):Null<KbInputController> return inputController( t );

/* === Computed Instance Fields === */

    // the KbInputController for DOWN events
    public var down(get, never):KbInputController;
    private inline function get_down() return ic( DOWN );

    // the KbInputController for UP events
    public var up(get, never):KbInputController;
    private inline function get_up() return ic( UP );

    // the KbInputController for PRESS events
    public var press(get, never):KbInputController;
    private inline function get_press() return ic( PRESS );

/* === Instance Fields === */

    private var inputControllers : InCtrl;
}

typedef InCtrl = {
    down: KbInputController,
    up: KbInputController,
    press: KbInputController
};
