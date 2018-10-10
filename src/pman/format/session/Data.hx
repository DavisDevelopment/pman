package pman.format.session;

import tannus.io.ByteArray;
import tannus.ds.Lazy;
import tannus.ds.Ref;
import tannus.ds.Pair;

import pman.bg.media.MediaSource;
import pman.bg.media.MediaType;

import haxe.extern.EitherType;
import haxe.ds.Either;
import haxe.ds.Option;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;

using Slambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.async.Asyncs;
using tannus.FunctionTools;

using pman.bg.PathTools;
using pman.bg.URITools;

/**
  mixin class which provides utility methods
 **/
class Data {

}

class Session {
    /* Constructor Function */
    public function new() {
        tabs = [new Tab()];
        focusedTabIndex = 0;
    }

/* === Methods === */

    public inline function addTab(tab: Tab):Tab {
        return tabs[tabs.push( tab ) - 1];
    }

    public inline function newTab():Tab {
        return addTab(new Tab());
    }

    public inline function focusedTab():Null<Tab> {
        return tabs[focusedTabIndex];
    }

    public function focus(i:Int, ?ti:Int) {
        focusedTabIndex = i;
        if (ti != null)
            focusedTab().focus( ti );
    }

/* === Variables === */

    public var tabs: Array<Tab>;
    public var focusedTabIndex: Int;
}

class Tab {
    /* Constructor Function */
    public function new(?q:Array<QueueItem>, i:Int=-1) {
        queue = q != null ? q : [];
        focusedItemIndex = i;

        #if debug
        switch focusedItemIndex {
            case (_ < 0 => true)|(_ >= queue.length => true):
                throw new pman.Errors.ValueError(focusedItemIndex, 'index out of bounds', 'IndexOutOfBoundsError');

            case _:
                // okeh
        }
        #end
    }

/* === Methods === */

    public inline function clone():Tab {
        return new Tab(queue.copy(), focusedItemIndex);
    }

    public inline function focusedItem():Null<QueueItem> {
        return queue[focusedItemIndex];
    }

    public inline function focus(i: Int):Null<QueueItem> {
        return queue[focusedItemIndex = i];
    }

    public inline function addItem(item: QueueItem) {
        queue.push( item );
    }

    public inline function addSrcItem(src: MediaSource) {
        addItem(new QueueItem( src ));
    }

/* === Variables === */

    public var queue: Array<QueueItem>;
    public var focusedItemIndex: Int;
}

class QueueItem {
    /* Constructor Function */
    public function new(src, ?id) {
        this.source = src;
        this.id = id;
        this.title = null;
        this.duration = null;
        this.lastTime = null;
        this.favorited = null;
        this.poster = null;
    }

/* === Methods === */

/* === Variables === */

    public var id(default, null): Null<String>;
    public var source(default, null): MediaSource;
    public var title(default, null): Null<String>;
    public var duration(default, null): Null<Float>;
    public var lastTime(default, null): Null<Float>;
    public var favorited(default, null): Null<Bool>;
    public var poster(default, null): Null<Img>;
}

class Img {
    /* Constructor Function */
    public function new(src) {
        this.src = src;
        mimeType = null;
        data = null;
    }

/* === Variables === */

    public var src(default, null): String;

    public var mimeType(default, null): Null<String>;
    public var data(default, null): Null<ByteArray>;
}
