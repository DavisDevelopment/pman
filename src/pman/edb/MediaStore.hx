package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;

import edis.libs.nedb.DataStore;
import edis.storage.db.Query;

import pman.bg.media.MediaRow as Row;
import pman.bg.media.MediaRow.MediaDataRow as DataRow;
import pman.bg.media.MediaRow.MediaMetadataRow as MetadataRow;

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

typedef MediaStore = pman.bg.db.MediaTable;
typedef MediaRow = Row;
typedef MediaDataRow = DataRow;
typedef MediaMetadataRow = MetadataRow;

class MediaStore_ extends TableWrapper {
    /* Constructor Function */
    public function new(store:DataStore):Void {
        super(store);
    }

/* === Instance Methods === */

    override function init(done : VoidCb):Void {
        var tasks = [];
        tasks.push(createIndex.bind('uri', true, false, _));
        super.init(function(?error) {
            if (error != null)
                return done(error);
            else
                tasks.series( done );
        });
    }

    /**
      * get all rows whose uri was in the [uris] list
      */
    public function getRowsByUris(uris:Array<String>, ?done:Cb<Array<Maybe<MediaRow>>>):ArrayPromise<Maybe<MediaRow>> {
        var queryDef:Query = new Query({
            uri: {
                "$in": uris
            }
        });
        return query(queryDef, done);
    }

    /**
      * get a single MediaRow by [uri]
      */
    public function getRowByUri(uri:String, ?done:Cb<Maybe<MediaRow>>):Promise<Maybe<MediaRow>> {
        return getBy('uri', uri, done);
    }
    //public function _getRowByUri(uri:String, done:Cb<Maybe<MediaRow>>) {
        //getRowByUri(uri).toAsync( done );
    //}

    /**
      * get a single row by id
      */
    public function getRowById(id:String, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return getById(id, done);
    }
    //public function _getRowById(id:String, done:Cb<Maybe<MediaRow>>) getRowById(id).toAsync( done );

    // get all rows
    public function allRows(?done : Cb<Array<MediaRow>>):ArrayPromise<MediaRow> {
        return all( done );
    }
    //public function _allRows(done:Cb<Array<MediaRow>>) {
        //return allRows().toAsync(done);
    //}

    // insert a new row
    public function insertRow(row:MediaRow, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return insert(row, done);
    }
    //public function _insertRow(row:MediaRow, done:Cb<MediaRow>) insertRow(row).toAsync(done);

    public function putRow(row:MediaRow, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return put(function(q:Query) {
            if (row._id != null)
                return q.eq('_id', row._id);
            else return q.eq('uri', row.uri);
        }, row, done);
    }
    //public function _putRow(row:MediaRow, done:Cb<MediaRow>) return putRow(row).toAsync(done);

    // create or get a row
    public function cogRow(uri:String, ?done:Cb<MediaRow>):Promise<MediaRow> {
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
        return cog(fn(_.eq('uri', uri)), newRow, null, done);
    }

    public function hasRowForUri(uri:String, ?done:Cb<Bool>):BoolPromise {
        return wrap(getRowByUri( uri ).transform.fn( _.exists ).bool(), done);
    }
    //public function _hasRowForUri(uri:String, done:Cb<Bool>) return hasRowForUri(uri).toAsync(done);

    public function deleteRow(row:MediaRow, done:VoidCb):Void {
        remove(function(q : Query) {
            if (row._id != null)
                return q.eq('_id', row._id);
            else return q.eq('uri', row.uri);
        }, done);
    }

    /**
      * delete, modify, and reinsert a row
      */
    public function refactorRow(row:MediaRow, mod:MediaRow->VoidCb->Void, done:Cb<MediaRow>):Promise<MediaRow> {
        return wrap(Promise.create({
            var _row:MediaRow = row;
            var steps = [deleteRow.bind(row, _)];
            steps.push(function(next) {
                mod(_row, next);
            });
            steps.push(function(next) {
                putRow(_row, function(?error, ?savedRow:MediaRow) {
                    if (error != null) {
                        next( error );
                    }
                    else if (savedRow != null) {
                        _row = savedRow;
                        next();
                    }
                });
            });
            steps.series(function(?error) {
                if (error != null) {
                    throw error;
                }
                else {
                    //done(null, _row);
                    return _row;
                }
            });
        }), done);
    }
}

/*
typedef MediaRow = {
    ?_id: String,
    uri: String,
    data: MediaDataRow
};

typedef MediaDataRow = {
    views: Int,
    starred: Bool,
    ?rating: Float,
    ?contentRating: String,
    ?channel: String,
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
*/
