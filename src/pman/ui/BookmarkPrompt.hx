package pman.ui;

import foundation.*;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.ds.Maybe;
import tannus.ds.Stack;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;

import Std.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class BookmarkPrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        title = 'bookmark name';
    }

/* === Instance Methods === */

    /**
      * handle keys
      */
    override function keydown(event : KeyboardEvent):Void {
        switch ( event.key ) {
            case Up:
                event.cancel();
                if (peekDistance == 0) {
                    originalValue = value;
                }
                peekDistance++;
                if (history.peek( peekDistance ) == null) {
                    peekDistance--;
                }
                value = history.peek( peekDistance );
                caret( value.length );

            case Down:
                event.cancel();
                if (peekDistance == 0) {
                    value = originalValue;
                }
                else {
                    value = history.peek( peekDistance-- );
                }
                caret( value.length );

            case _:
                super.keydown( event );
        }
    }

    /**
      * do the shit
      */
    override function line(l : String):Void {
        if (l != history.peek()) {
            history.add( l );
        }
        super.line( l );
    }

/* === Instance Fields === */

    private var peekDistance : Int = 0;
    private var originalValue : String;

/* === Statics === */

    public static var history : Stack<String> = {new Stack();};
}
