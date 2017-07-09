package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.sys.Path;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringTools;
using Slambda;
using tannus.ds.ArrayTools;

/*
   provides collection entries to the collection asynchronously, in chunks
*/
class CollectionSource {
    /* Constructor Function */
    public function new():Void {
        isOpen = false;
        length = null;
        chunkSize = 10;
    }

/* === Instance Methods === */

    public function loadChunk(index:Int, complete:Cb<CollectionChunk>):Void {
        throw 'unimplemented';
    }

    public function open(complete : VoidCb):Void {
        defer(function() {
            isOpen = true;
            length = 0;

            complete();
        });
    }

    public function close(complete : VoidCb):Void {
        defer(function() {
            isOpen = false;

            complete();
        });
    }

/* === Instance Fields === */

    public var isOpen(default, null):Bool;
    public var length(default, null):Maybe<Int>;
    public var numberOfEntries(default, null)
    public var chunkSize : Int;
}

typedef CollectionChunk = Array<CollectionEntry>;
