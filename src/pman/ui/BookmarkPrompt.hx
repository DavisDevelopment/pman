package pman.ui;

import foundation.*;

import tannus.io.*;
import tannus.ds.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;
import pman.bg.media.Mark;

import Std.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

@:expose
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
                if (peekDistance == -1) {
                    originalValue = value;
                }

                peekDistance++;
                if (history[peekDistance] == null) {
                    peekDistance--;
                }

                value = history[peekDistance];
                caret( value.length );

            case Down:
                event.cancel();
                if (peekDistance == -1) {
                    value = originalValue;
                }
                else {
                    value = history[0 + peekDistance--];
                }
                caret( value.length );

            case _:
                peekDistance = -1;
                super.keydown( event );
        }
    }

    /**
      * do the shit
      */
    override function line(l : String):Void {
        //if (l != history[0]) {
            //history.unshift( l );
            addHistoryItem( l );
        //}
        super.line( l );
    }

    /**
      * add an item to the [history]
      */
    private function addHistoryItem(line: String):Void {
        var rem = [];
        for (item in history) {
            if (item.trim() == line.trim()) {
                rem.push( item );
            }
        }
        history = history.without( rem );
        history.unshift(line.trim());
    }

/* === Instance Fields === */


    private var peekDistance : Int = -1;
    private var originalValue : String;

/* === Statics === */

    public static var history : Array<String> = {new Array();};
}
