package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.async.*;

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
        return getAll('media_items');
    }
    public function getAllMediaItemRows_(done : Cb<Array<MediaItemRow>>):Void {
        getAllMediaItemRows().then(done.yield()).unless(done.raise());
    }

    /**
      * get an array of all media items
      */
    public function getAllMediaItems():ArrayPromise<MediaItem> {
        return getAllMediaItemRows().vmap(function(row) {
            return mediaItem( row );
        });
    }

    /**
      * request a media_item row by its primary key
      */
    public function getMediaItemRow(id : Int):Promise<Null<MediaItemRow>> {
        return get('media_items', id);
    }

    /**
      * select by 'uri'
      */
    public function getMediaItemRowByUri(uri : String):Promise<Null<MediaItemRow>> {
        return cast select('media_items', {
            uri: uri
        });
    }
    public function getMediaItemRowByUri_(uri:String, cb:Cb<MediaItemRow>):Void {
        getMediaItemRowByUri( uri ).then(cb.yield()).unless(cb.raise());
    }

    
    public function getMediaItemByUri(uri : String):Promise<Null<MediaItem>> {
        return getMediaItemRowByUri( uri ).transform(function(row : Null<MediaItemRow>) {
            return (row != null ? mediaItem( row ) : null);
        });
    }

    /**
      * get the id of a media_item row by its uri
      */
    public function getMediaItemIdByUri(uri:String, cb:Cb<Int>):Void {
        getMediaItemRowByUri( uri ).then(function(row:Null<MediaItemRow>) {
            if (row != null)
                return cb(null, row.id);
            else
                return cb();
        }).unless( cb );
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
        return get('media_info', id);
    }
    public function getMediaInfoRow_(id:Int, done:Cb<MediaInfoRow>):Void {
        getMediaInfoRow( id ).then(done.yield()).unless(done.raise());
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
                    tags: [],
                    actors: [],
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
    public function newMediaItemRowFor_(uri:String, done:Cb<MediaItemRow>):Void {
        newMediaItemRowFor( uri ).then(done.yield()).unless(done.raise());
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
    tags : Array<Int>,
    actors : Array<Int>,
    meta : Null<MediaInfoRowMeta>
    //?rating : Float,
    //?description : String
};

typedef MediaInfoRowMeta = {
    duration : Float,
    video : Null<{
        width:Int,
        height:Int//,
        //?frame_rate: String,
        //?time_base: String
    }>,
    audio: Null<{}>
};
