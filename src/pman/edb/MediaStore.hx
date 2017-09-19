package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;

import nedb.DataStore;

import Slambda.fn;
import tannus.math.TMath.*;
import haxe.extern.EitherType;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.async.VoidAsyncs;
using pman.edb.MediaRowTools;

class MediaStore extends TableWrapper {
    /* Constructor Function */
    public function new(db:PManDatabase, store:DataStore):Void {
        super(db, store);
    }

/* === Instance Methods === */

    /**
      * get a single MediaRow by [uri]
      */
    public function getRowByUri(uri : String):Promise<Maybe<MediaRow>> {
        return getBy('uri', uri);
    }
    public function _getRowByUri(uri:String, done:Cb<Maybe<MediaRow>>) {
        getRowByUri(uri).toAsync( done );
    }

    /**
      * get a single row by id
      */
    public function getRowById(id : String):Promise<MediaRow> {
        return getById( id );
    }
    public function _getRowById(id:String, done:Cb<Maybe<MediaRow>>) getRowById(id).toAsync( done );

    // get all rows
    public function allRows():ArrayPromise<MediaRow> {
        return all();
    }
    public function insertRow(row : MediaRow):Promise<MediaRow> {
        return insert( row );
    }

    public function _cogRow(uri:String, done:Cb<MediaRow>):Void {
        function newRow():MediaRow {
            return {
                uri: uri,
                data: {
                    views: 0,
                    starred: false,
                    marks: [],
                    tags: [],
                    actors: [],
                    meta: null
                }
            };
        }
        _cog(fn(_.eq('uri', uri)), newRow, null, done);
    }
    public function cogRow(uri:String):Promise<MediaRow> {
        return _cogRow.bind(uri, _).toPromise();
    }
}

typedef MediaRow = {
    ?_id: String,
    uri: String,
    data: MediaDataRow
};

typedef MediaDataRow = {
    views: Int,
    starred: Bool,
    ?rating: Float,
    ?description: String,
    marks: Array<String>,
    tags: Array<String>,
    actors: Array<String>,
    meta: Null<MediaMetadataRow>
}

typedef MediaMetadataRow = {
    duration : Float,
    video : Null<{
        width:Int,
        height:Int,
        frame_rate: String,
        time_base: String
    }>,
    audio: Null<{}>
};
