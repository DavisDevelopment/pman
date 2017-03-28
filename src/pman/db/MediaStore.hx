package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;

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

class MediaStore extends TableWrapper {
    /* Constructor Function */
    public function new(dbr : PManDatabase):Void {
        super( dbr );
    }

/* === Instance Methods === */

    /**
      * get an Array of all media item rows
      */
    public function getAllMediaItemRows():ArrayPromise<MediaItemRow> {
        var store = tos('media_items');
        return store.getAll().transform(function(dynlist:Array<Dynamic>):Array<MediaItemRow> {
            return cast dynlist;
        }).array();
    }

    /**
      * get an array of all media items
      */
    public function getAllMediaItems():ArrayPromise<MediaItem> {
        return getAllMediaItemRows().map(function(row) {
            return mediaItem( row );
        });
    }

    /**
      * request a media_item row by its primary key
      */
    public function getMediaItemRow(id : Int):Promise<Null<MediaItemRow>> {
        var t = db.transaction('media_items');
        var store = t.objectStore('media_items');
        function toMediaItem(dyn : Dynamic):Null<MediaItemRow> {
            return cast dyn;
        }
        var prom = store.get( id ).transform( toMediaItem );
        t.complete.once(function() {
            trace('transaction complete');
        });
        return prom;
    }

    public function getMediaItemRowByUri(uri : String):Promise<Null<MediaItemRow>> {
        return cast select('media_items', {
            uri: uri
        });
    }

    /**
      * obtain a media_item row by its URI when the primary key is not known
      */
    public function getMediaItemRowByUri_(uri : String):Promise<Null<MediaItemRow>> {
        return Promise.create({
            var row:Null<MediaItemRow> = null;
            var store = tos( 'media_items' );

            // iterate over all rows
            function cursorStep(cursor:Cursor, walker:CursorWalker) {
                if (cursor.entry != null) {
                    // we now have the current row to work with
                    var cr:Dynamic = cursor.entry;
                    if (row == null && cr.uri == uri) {
                        row = cast cr;
                    }
                }
                cursor.next();
            }

            var cursorWalker:CursorWalker = store.openCursor( cursorStep );
            cursorWalker.complete.once(function() {
                trace('cursor-iteration complete');
                return row;
            });
            cursorWalker.error.once(function(error) {
                throw error;
            });
        });
    }
    public function getMediaItemByUri(uri : String):Promise<Null<MediaItem>> {
        return getMediaItemRowByUri( uri ).transform(function(row : Null<MediaItemRow>) {
            return (row != null ? mediaItem( row ) : null);
        });
    }

    /**
      * check for existance of a row with the given uri
      */
    public function hasRowForUri(uri:String, callback:Bool->Void):Void {
        getMediaItemRowByUri( uri ).then(function(row) {
            callback(row != null);
        });
    }

    /**
      * push updated [row] object onto the table
      */
    public inline function putMediaItemRow(row : MediaItemRow):Promise<Null<MediaItemRow>> {
        return put('media_items', row);
    }

    /**
      * put a media_info row onto the table
      */
    public function putMediaInfoRow(row : MediaInfoRow):Promise<MediaInfoRow> {
        return put('media_info', row);
    }
    public function putMediaInfoRow_(row:MediaInfoRow, done:Null<Dynamic>->Void):Void {
        var prom = putMediaInfoRow( row );
        prom.then(function(nrow){
            done( null );
        });
        prom.unless(function(error){
            done( error );
        });
    }

    /**
      * retrieve the media_info row associated with the given id
      */
    public function getMediaInfoRow(id : Int):Promise<MediaInfoRow> {
        return Promise.create({
            var store = tos( 'media_info' );
            @forward store.get( id ).transform.fn(cast _);
        });
    }

    /**
      * create/push a new row for the given uri
      */
    public function newMediaItemRowFor(uri : String):Promise<MediaItemRow> {
        return Promise.create({
            var media_item:MediaItemRow = {uri: uri};
            
            //TODO load new metadata by default
            var mip = putMediaItemRow( media_item );
            mip.then(function( row ) {
                var media_info:MediaInfoRow = {
                    id: row.id,
                    views: 0,
                    starred: false,
                    marks: [],
                    meta: null
                };

                // pop that shit into the database
                putMediaInfoRow_(media_info, function(err : Null<Dynamic>) {
                    if (err == null) {
                        return row;
                    }
                    else {
                        throw err;
                    }
                });
            });
            mip.unless(function( error ) {
                throw error;
            });
        });
    }

    /**
      * request the media_item row for the given URI
      ----
      * if that succeeds, yield the retrieved row
      * if it fails, create a new row and push it onto the table, then yield the newly created row
      */
    public function cogMediaItemRow(uri : String):Promise<MediaItemRow> {
        return Promise.create({
            var mirp = getMediaItemRowByUri( uri );
            mirp.unless(function( error ) {
                throw error;
            });
            mirp.then(function(row : Null<MediaItemRow>) {
                if (row != null) {
                    return row;
                }
                else {
                    //@forward putMediaItemRow({uri : uri});
                    @forward newMediaItemRowFor( uri );
                }
            });
        });
    }
    public function cogMediaItem(uri : String):Promise<MediaItem> {
        return cogMediaItemRow(uri).transform( mediaItem );
    }
    
    /**
      * build and return a MediaItem instance from the given row
      */
    public function mediaItem(row : MediaItemRow):MediaItem {
        return new MediaItem(this, row);
    }
}

typedef MediaItemRow = {
    ?id : Int,
	uri : String
};

typedef MediaInfoRow = {
    id : Int,
    views : Int,
    starred : Bool,
    marks : Array<String>,
    meta : Null<MediaInfoRowMeta>
};

typedef MediaInfoRowMeta = {
    duration : Float,
    video : Null<{width:Int, height:Int}>,
    audio: Null<{}>
};
