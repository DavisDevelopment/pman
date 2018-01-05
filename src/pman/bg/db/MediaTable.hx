package pman.bg.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import edis.libs.nedb.*;
import edis.storage.db.*;
import edis.core.Prerequisites;

import Slambda.fn;
import edis.Globals.*;
import haxe.extern.EitherType;

import pman.bg.Dirs;
import pman.bg.media.*;
import pman.bg.media.MediaRow;
import pman.bg.media.MediaData;
import pman.bg.media.Media;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class MediaTable extends Table {
    /* Constructor Function */
    public function new(store: DataStore):Void {
        super( store );
    }

/* === MediaRow Methods === */

    /**
      * initialize [this] Table
      */
    override function init(done: VoidCb):Void {
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
      * get an Array of MediaRows from an Array of 'keys' (Strings representing either an ID or URI)
      */
    public function getRowsByKeys(keys:Array<String>, ?done:Cb<Array<Maybe<MediaRow>>>):ArrayPromise<Maybe<MediaRow>> {
        var queryDef:Query = new Query({id: {"$in": keys}}).or({uri:{"$in": keys}});
        return query(queryDef, done);
    }

    /**
      * get a single MediaRow by [uri]
      */
    public function getRowByUri(uri:String, ?done:Cb<Maybe<MediaRow>>):Promise<Maybe<MediaRow>> {
        return getBy('uri', uri, done);
    }

    /**
      * get a single row by id
      */
    public function getRowById(id:String, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return getById(id, done);
    }

    /**
      * get a MediaRow from a 'key'
      */
    public function getRowByKey(key:String, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return queryOne(function(q: Query) {
            return q.eq('id', key).or.fn(_.eq('uri', key));
        }, done);
    }

    /**
      * get all MediaRow objects
      */
    public function allRows(?done : Cb<Array<MediaRow>>):ArrayPromise<MediaRow> {
        return all( done );
    }

    /**
      * insert a MediaRow object into [this] Table
      */
    public function insertRow(row:MediaRow, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return insert(row, done);
    }

    /**
      * update/insert a MediaRow
      */
    public function putRow(row:MediaRow, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return put(function(q: Query) {
            if (row._id != null) {
                return q.eq('_id', row._id);
            }
            else {
                return q.eq('uri', row.uri);
            }
        }, row, done);
    }

    /**
      * create or get a MediaRow
      */
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

    /**
      * check if there is a row in [this] Table for the given uri
      */
    public function hasRowForUri(uri:String, ?done:Cb<Bool>):BoolPromise {
        return wrap(getRowByUri( uri ).transform.fn( _.exists ).bool(), done);
    }

    /**
      * delete a MediaRow from [this] Table
      */
    public function deleteRow(row:MediaRow, done:VoidCb):Void {
        remove(function(q : Query) {
            if (row._id != null) {
                return q.eq('_id', row._id);
            }
            else {
                return q.eq('uri', row.uri);
            }
        }, done);
    }

    /**
      * iterate over each MediaRow in [this] Table and apply [action] to it
      */
    public function eachRow(action:MediaRow->Void, ?done:VoidCb):VoidPromise {
        var promise:VoidPromise = new VoidPromise(function(accept, reject) {
            each(function(row: MediaRow) {
                action( row );
            }, function(?error) {
                if (error != null) {
                    return reject( error );
                }
                else {
                    accept();
                }
            });
        });
        if (done != null) {
            promise.then(done.void(), done.raise());
        }
        return promise;
    }

/* === Media Methods === */

    /**
      * get a Media instance by id from [this] Table
      */
    //public function getMediaById(id:String, ?done:Cb<Media>):Promise<Media> {
        //return mp(getRowById( id ), done);
    //}

    /**
      * get a Media instance by uri from [this] Table
      */
    //public function getMediaByUri(uri:String, ?done:Cb<Media>):Promise<Media> {
        //return mp(getRowByUri( uri ), done);
    //}

    /**
      * get all Media
      */
    //public function allMedia(?done: Cb<Array<Media>>):ArrayPromise<Media> {
        //return amp(allRows(), done);
    //}

    /**
      * insert a media instance
      */
    //public function insertMedia(media:Media, ?done:Cb<Media>):Promise<Media> {
        //return mp(insertRow(media.toRow()), done);
    //}

    /**
      * insert or update a media instance
      */
    //public function putMedia(media:Media, ?done:Cb<Media>):Promise<Media> {
        //return mp(putRow(media.toRow()), done);
    //}

    /**
      * create or get a media instance
      */
    //public function cogMedia(uri:String, ?done:Cb<Media>):Promise<Media> {
        //return mp(cogRow(uri), done);
    //}

    /**
      * convert a Promise<MediaRow> to a Promise<Media>
      */
    //private inline function mp(promise:Promise<MediaRow>, ?done:Cb<Media>):Promise<Media> {
        //var res:Promise<Media> = promise.transform(row->row.toMedia());
        //if (done != null) {
            //res.toAsync( done );
        //}
        //return res;
    //}

    //private inline function amp(promise:ArrayPromise<MediaRow>, ?done:Cb<Array<Media>>):ArrayPromise<Media> {
        //var res:ArrayPromise<Media> = promise.map(row->row.toMedia());
        //if (done != null) {
            //res.toAsync( done );
        //}
        //return res;
    //}

/* === Instance Fields === */
}
