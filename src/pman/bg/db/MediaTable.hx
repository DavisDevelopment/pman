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
import pman.bg.media.MediaDataDelta;

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
        //tasks.push(createIndex.bind('uri', true, false, _));
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
        if (keys.length == 1) {
            return wrap(getRowByKey(keys[0]).transform.fn(row => [row].compact()).array(), done);
        }

        var queryDef:Query = new Query({id: {"$in": keys}}).or({uri:{"$in": keys}});
        trace(queryDef.toObject());
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
        var queryDef:Query = qd(function(q:Query) {
            return (q.eq('id', key).or(fn(q => q.eq('uri', key))));
        });
        trace(queryDef.toObject());
        return queryOne(queryDef, done);
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

    /**
      * apply changes to a certain MediaRow
      */
    public function refactorRow(row:EitherType<MediaRow, Thunk<Promise<MediaRow>>>, mod:MediaRow->VoidCb->Void, ?done:Cb<MediaRow>):Promise<MediaRow> {
        return wrap(Promise.create({
            var prow = pthunk( row );
            prow.then(function(row: MediaRow) {
                var _row:MediaRow = Reflect.copy( row );
                var steps:Array<VoidAsync> = [deleteRow.bind(row, _)];
                steps.push(function(next) {
                    mod(_row, next);
                });
                steps.push(function(next) {
                    putRow(_row, function(?error, ?savedRow:MediaRow) {
                        if (error != null) {
                            next( error );
                        }
                        else {
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
                        return _row;
                    }
                });
            });
            prow.unless(function(error: Dynamic) {
                throw error;
            });
        }), done);
    }

    private function pthunk(row:EitherType<MediaRow, Thunk<Promise<MediaRow>>>):Promise<MediaRow> {
        if ((row is Promise<MediaRow>) || Reflect.isFunction( row )) {
            var thunk:Thunk<Promise<MediaRow>> = new Thunk(untyped row);
            return thunk.resolve();
        }
        else {
            return Promise.resolve(untyped row);
        }
    }

/* === Media Methods === */

/* === Instance Fields === */
}
