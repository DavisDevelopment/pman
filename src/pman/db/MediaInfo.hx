package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.db.MediaStore;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaInfo {
    /* Constructor Function */
    public function new(store:MediaStore, item:MediaItem, row:MediaInfoRow):Void {
        this.store = store;
        this.row = row;
        this.mediaItem = item;
    }

/* === Instance Methods === */

    /**
      * pull remote data onto [this]
      */
    public function pull(done : Void->Void):Void {
        var mirp = store.getMediaInfoRow( id );
        mirp.then(function(remoteRow : Null<MediaInfoRow>) {
            if (remoteRow != null) {
                this.row = remoteRow;
            }
        });
        mirp.unless(function(error) {
            trace('Error: $error');
        });
    }

    /**
      * write [this]'s data onto the row in the database
      */
    public function push(?done : Void->Void):Void {
        store.putMediaInfoRow_(row, function(error : Null<Dynamic>) {
            if (error != null) {
                trace('Error: $error');
            }
            else {
                if (done != null) 
                    done();
            }
        });
    }

    /**
      * deallocate [this] Model's memory
      */
    public function dispose():Void {
        store = null;
        row = null;
        mediaItem = null;
    }

/* === Computed Instance Fields === */

    public var id(get, never):Int;
    private inline function get_id():Int return row.id;

    public var views(get, set):Int;
    private inline function get_views():Int return row.views;
    private inline function set_views(v : Int):Int return (row.views = v);

    public var tagIds(get, set):Array<Int>;
    private inline function get_tagIds():Array<Int> return row.tags;
    private inline function set_tagIds(a : Array<Int>):Array<Int> return (row.tags = a);

    public var actorIds(get, set):Array<Int>;
    private inline function get_actorIds():Array<Int> return row.actors;
    private inline function set_actorIds(a : Array<Int>):Array<Int> return (row.actors = a);

    public var rating(get, set):MediaInfoRating;
    private inline function get_rating() return row.rating;
    private inline function set_rating(v : MediaInfoRating) return (row.rating = v);

    public var time(get, set):MediaInfoTime;
    private inline function get_time() return row.time;
    private inline function set_time(v : MediaInfoTime) return (row.time = v);

/* === Instance Fields === */

    public var store : MediaStore;
    public var row : MediaInfoRow;
    public var mediaItem : MediaItem;
}
