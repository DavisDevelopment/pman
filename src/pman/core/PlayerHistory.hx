package pman.core;

import haxe.extern.EitherType;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.math.Random;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.FileFilter;

import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.core.history.PlayerHistoryItem;
import pman.core.history.PlayerHistoryItem as PHItem;

import foundation.Tools.*;

using Std;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;
using pman.media.MediaTools;
using pman.core.history.PlayerHistoryTools;

class PlayerHistory {
    /* Constructor Function */
    public function new(ps : PlayerSession):Void {
        session = ps;
        currentIndex = 0;
        a = new Array();
    }

/* === Instance Methods === */

    /**
      * 'pop' the given item
      */
    public function pop(?item : PHItem):Void {
        if (item == null) {
            item = currentItem;
            if (item == null) {
                return ;
            }
        }
        
        switch ( item ) {
            case Media( mitem ):
                switch ( mitem ) {
                    case LoadTrack( track ):
                        ps.load(track, {
                            trigger: 'history'
                        });
                }
        }
    }

    /**
      * go back
      */
    public function goBack():Void {
        goToOffset( -1 );
    }

    /**
      * go forward
      */
    public function goForward():Void {
        goToOffset( 1 );
    }

    /**
      * check whether it is possible to navigate backward in the history
      */
    public inline function canGoBack():Bool {
        return canGoToOffset( -1 );
    }

    /**
      * check whether it is possible to navigate forward in the history
      */
    public inline function canGoForward():Bool {
        return canGoToOffset( 1 );
    }

    /**
      * add an item
      */
    public function push(item : PHItem):Void {
        _trim();
        if (shouldOverwrite(item, last)) {
            last = item;
        }
        else {
            currentIndex = (a.push( item ) - 1);
        }
    }

    /**
      * get an item in the stack without moving to it
      */
    public inline function get(index : Int):Maybe<PHItem> {
        return a[ index ];
    }
    public inline function peek(offset:Int=0):Maybe<PHItem> {
        return get(offsetIndex( offset ));
    }

    /**
      * navigate to the given offset
      */
    public function goToOffset(offset : Int):Void {
        var item:Maybe<PHItem> = peek( offset );
        if (item == null) {
            throw PHError.PHE_InvalidOffset( offset );
        }
        else {
            seekOffset( offset );
            pop();
        }
    }

    /**
      * navigate to the given index
      */
    public function goToIndex(index : Int):Void {
        var item:Maybe<PHItem> = get( index );
        if (item == null) {
            throw PHError.PHE_InvalidIndex( index );
        }
        else {
            seek( index );
            pop();
        }
    }

    /**
      * check whether it is possible to go to the given offset
      */
    public inline function canGoToOffset(offset : Int):Bool {
        return (peek( offset ) != null);
    }

    /**
      * check whether it is possible to go to the given index
      */
    public inline function canGoToIndex(index : Int):Bool {
        return (get( index ) != null);
    }

    /**
      * set the current index, and then react to the change as necessary
      */
    public function setCurrentIndex(index : Int):Void {
        currentIndex = index.clamp(0, (length - 1));
    }
    public inline function seek(i : Int) setCurrentIndex( i );
    public inline function seekOffset(i : Int) seek(offsetIndex( i ));

    /**
      * snip off all items from [currentIndex] to the end of the state
      */
    public inline function _trim():Array<PHItem> {
        var pos = (length - currentIndex - 1);
        return a.splice(-pos, pos);
    }

    /**
      * get the absolute index for the given offset
      */
    private inline function offsetIndex(offset : Int):Int {
        return (currentIndex + offset);
    }

/* === validation methods === */

    /**
      * test whether [b] should overwrite [a]
      */
    private inline function shouldOverwrite(a:PHItem, b:Null<PHItem>):Bool {
        return (b == null || a.shouldOverwrite( b ));
    }

/* === Computed Instance Fields === */

    public var length(get, never):Int;
    private inline function get_length():Int return a.length;

    public var currentItem(get, never):Null<PHItem>;
    private inline function get_currentItem():Null<PHItem> return get( currentIndex );

    private var last(get, set):Null<PHItem>;
    private inline function get_last():Null<PHItem> return a[length - 1];
    private inline function set_last(v : Null<PHItem>):Null<PHItem> return (a[length - 1] = v);

    private var first(get, never):Null<PHItem>;
    private inline function get_first():Null<PHItem> return a[0];

    private var ps(get, never):PlayerSession;
    private inline function get_ps() return session;

/* === Instance Fields === */

    public var session(default, null):PlayerSession;
    public var currentIndex(default, null):Int;

    private var a : Array<PHItem>;
}

enum PHError {
    PHE_InvalidOffset(offset : Int);
    PHE_InvalidIndex(index : Int);
}
