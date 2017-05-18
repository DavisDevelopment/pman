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

@:enum
abstract KeyboardEventType (String) to String {
    var DOWN = 'keydown';
    var UP = 'keyup';
    var PRESS = 'keypress';

    @:from
    public static function fromString(s : String):KeyboardEventType {
        s = s.toLowerCase().trim();
        switch ( s ) {
            case 'keydown', 'down':
                return DOWN;
            case 'keyup', 'up':
                return UP;
            case 'keypress', 'press':
                return PRESS;

            default:
                throw 'Error: Invalid KeyboardEventType "$s"';
        }
    }
}
