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

import pman.bg.Dirs;
import pman.bg.media.*;
import pman.bg.media.TagRow;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class TagTable extends Table {
    /* Constructor Function */
    public function new(store: DataStore):Void {
        super( store );
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(done: VoidCb):Void {
        var tasks = [];
        tasks.push(createIndex.bind('name', true, false, _));
        super.init(function(?error) {
            if (error != null)
                return done(error);
            else
                tasks.series( done );
        });
    }

    /**
      * 
      */
    public function getRowsByNames(names:Array<String>, ?done:Cb<Array<Maybe<TagRow>>>):ArrayPromise<Maybe<TagRow>> {
        var queryDef:Query = new Query({
            name: {
                "$in": names
            }
        });
        return query(queryDef, done);
    }

    public function cogRows(names:Array<String>, ?done:Cb<Array<TagRow>>):ArrayPromise<TagRow> {
        var _names = names.copy();
        var steps:Array<VoidAsync> = new Array();
        var results:Array<TagRow> = new Array();
        
        return wrap(new Promise(function(accept, reject) {
            getRowsByNames( names ).then(function(rows) {
                for (row in rows) {
                    if (row != null) {
                        names.remove( row.name );
                        results.push( row );
                    }
                }
                for (name in names) {
                    steps.push(function(next) {
                        createRow(name, function(?error, ?row) {
                            if (error != null) {
                                next( error );
                            }
                            else {
                                results.push( row );
                                next();
                            }
                        });
                    });
                }
                steps.series(function(?error) {
                    if (error != null) {
                        reject( error );
                    }
                    else {
                        results.sort(function(a, b) {
                            return Reflect.compare(names.indexOf(a.name), names.indexOf(b.name));
                        });
                        accept( results );
                    }
                });
            }, reject);
        }).array(), done);
    }

    /**
      * get all TagRows
      */
    public function allRows(?done:Cb<Array<TagRow>>):ArrayPromise<TagRow> {
        return all( done );
    }

    /**
      * create or get a TagRow
      */
    public function cogRow(name:String, ?done:Cb<TagRow>):Promise<TagRow> {
        function newRow():TagRow {
            return {
                name: name
            };
        }

        var query:Query = qd(fn(_.eq('name', name)));

        return cog(query, newRow, null, done);
    }

    public function createRow(name:String, ?done:Cb<TagRow>):Promise<TagRow> {
        return insert({
            name: name
        }, done);
    }
}
