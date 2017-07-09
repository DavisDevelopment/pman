package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.sys.Path;

import gryffin.display.Canvas;
import gryffin.display.Image;

import js.html.Element;
import js.html.CanvasElement;
import js.html.ImageElement;

import haxe.extern.EitherType as Either;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class CollectionEntry {
    /* Constructor Function */
    public function new():Void {
        entryType = null;
    }

/* === Instance Methods === */

    /**
      * obtain [this]'s name
      */
    public function getName():String {
        return 'CollectionEntry';
    }

    /**
      * obtain the icon/thumbnail for [this]
      */
    public function getIcon():Maybe<CollectionEntryIcon> {
        return null;
    }

    /**
      * get the number of sub-entries
      */
    public function getNumberOfEntries():Int {
        return 0;
    }

    /**
      * get the specified chunk of sub-entries
      */
    public function getEntries(?chunkIndex : Int):ArrayPromise<CollectionEntry> {
        throw 'not implemented';
    }

/* === Instance Fields === */

    public var entryType : CollectionEntryType;
}

typedef TCollectionEntryIcon = Either<Either<Image, ImageElement>, Either<Canvas, CanvasElement>>;

abstract CollectionEntryIcon (TCollectionEntryIcon) from TCollectionEntryIcon to TCollectionEntryIcon {
    /* Constructor Function */
    public inline function new(i : TCollectionEntryIcon) {
        this = i;
    }

    /**
      * transform into an Element
      */
    @:to
    public function toElement():Element {
        if ((this is Element))
            return this;
        else if ((this is Image))
            return @:privateAccess cast(this, Image).img;
        else if ((this is Canvas))
            return @:privateAccess cast(this, Canvas).canvas;
        else
            throw 'Invalid CollectionEntryIcon';
    }
}
