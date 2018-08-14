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
import pman.bg.media.ActorRow;
import pman.bg.media.Actor;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class ActorTable extends Table {
    /* Constructor Function */
    public function new(store: DataStore):Void {
        super( store );
    }

/* === Instance Methods === */

    /**
      * initialize [this] table
      */
    override function init(done : VoidCb):Void {
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
      * get an Array of ActorRows from an Array of names
      */
    public function getRowsByNames(names:Array<String>, ?done:Cb<Array<Maybe<ActorRow>>>):ArrayPromise<Maybe<ActorRow>> {
        var queryDef:Query = new Query({
            name: {
                "$in": names
            }
        });
        return query(queryDef, done);
    }

    /**
      * from an Array of names, get an Array of ActorRows, creating those that don't exist
      */
    public function cogRowsFromNames(names:Array<String>, ?done:Cb<Array<ActorRow>>):ArrayPromise<ActorRow> {
        // create list to hold all the steps
        var asyncs:Array<Async<ActorRow>> = new Array();

        // build out the array of steps
        for (name in names) {
            asyncs.push(untyped cogRow.bind(name, _));
        }

        // create the Promise
        return wrap(Promise.create({
            if (asyncs.empty()) {
                defer(function() {
                    return new Array();
                });
            }
            else {
                asyncs.series(function(?error, ?rows) {
                    if (error != null) {
                        trace( error );
                        throw error;
                    }
                    else if (rows != null) {
                        return rows;
                    }
                    else {
                        throw 'Error: No data retrieved';
                    }
                });
            }
        }).array(), done);
    }

    /**
      * get all ActorRow objects
      */
    public function allRows(?done:Cb<Array<ActorRow>>):ArrayPromise<ActorRow> return all( done );

    /**
      * get row by name
      */
    public function getRowByName(name:String, ?done:Cb<Maybe<ActorRow>>):Promise<Maybe<ActorRow>> {
        return getBy('name', name, done);
    }

    /**
      * get row by id
      */
    public function getRowById(id:String, ?done:Cb<Maybe<ActorRow>>):Promise<Maybe<ActorRow>> {
        return getById(id, done);
    }

    /**
      * insert an ActorRow
      */
    public function insertRow(row:ActorRow, ?done:Cb<ActorRow>):Promise<ActorRow> return insert(row, done);

    /**
      * insert or update an ActorRow
      */
    public function putRow(row:ActorRow, ?done:Cb<ActorRow>):Promise<ActorRow> {
        return put(function(q: Query) {
            if (row._id != null) {
                return q.eq('_id', row._id);
            }
            else {
                return q.eq('name', row.name);
            }
        }, row, done);
    }

    /**
      * create or get an ActorRow object
      */
    public function cogRow(name:String, ?done:Cb<ActorRow>):Promise<ActorRow> {
        function newRow():ActorRow {
            return {
                name: name,
                aliases: null,
                dob: null
            };
        }
        return cog(fn(_.eq('name', name)), newRow, null, done);
    }

    /**
      * check for the existence of a Row for [name]
      */
    public function hasRowForName(name:String, ?done:Cb<Bool>):BoolPromise {
        return wrap(getRowByName( name ).transform.fn( _.exists ).bool(), done);
    }

    /**
      * get all Actor instances from [this] Table
      */
    public function allActors(?done:Cb<Array<Actor>>):ArrayPromise<Actor> {
        return wrap(aprta(allRows()), done);
    }

    /**
      * get an Actor instance by name
      */
    public function getActorByName(name:String, ?done:Cb<Maybe<Actor>>):Promise<Maybe<Actor>> {
        return wrap(prta(getRowByName(name)), done);
    }

    /**
      * get an Actor by id
      */
    public function getActorById(id:String, ?done:Cb<Maybe<Actor>>):Promise<Maybe<Actor>> {
        return wrap(prta(getRowById(id)), done);
    }

    /**
      * insert an Actor instance into [this] Table
      */
    public function insertActor(actor:Actor, ?done:Cb<Actor>):Promise<Actor> {
        return wrap(prta(untyped insertRow(actor.toRow())), done);
    }

    /**
      * insert or update an Actor instance
      */
    public function putActor(actor:Actor, ?done:Cb<Actor>):Promise<Actor> {
        return wrap(prta(untyped putRow(actor.toRow())), done);
    }

    /**
      * create or get an Actor instance
      */
    public function cogActor(name:String, ?done:Cb<Actor>):Promise<Actor> {
        return wrap(prta(untyped cogRow( name )), done);
    }

    /**
      *
      */
    public function cogActorsFromNames(names:Array<String>, ?done:Cb<Array<Actor>>):ArrayPromise<Actor> {
        return wrap(aprta(untyped cogRowsFromNames( names )), done);
    }

    private inline function pta<T>(promise:Promise<T>, ?callback:Cb<T>):Promise<T> {
        if (callback != null) {
            promise.toAsync( callback );
        }
        return promise;
    }

    private inline function prta(p : Promise<Maybe<ActorRow>>):Promise<Maybe<Actor>> {
        return p.transform( mrta );
    }

    private inline function aprta(p : ArrayPromise<Maybe<ActorRow>>):ArrayPromise<Maybe<Actor>> {
        return p.vmap( mrta );
    }

    private inline function mrta(row : Maybe<ActorRow>):Maybe<Actor> {
        return row.ternary(rta( _ ), null);
    }

    private inline function rta(row : ActorRow):Actor {
        return new Actor( row );
    }
}
