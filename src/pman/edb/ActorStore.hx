package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;
import pman.media.info.Actor;

import edis.libs.nedb.DataStore;
import edis.storage.db.Query;

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

class ActorStore extends TableWrapper {
    /* Constructor Function */
    public function new(store:DataStore):Void {
        super(store);
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
    public function getRowsByNames(names : Array<String>):ArrayPromise<Maybe<ActorRow>> {
        var queryDef:Query = new Query({
            name: {
                "$in": names
            }
        });
        return query( queryDef );
    }
    public function _getRowsByNames(names:Array<String>, done:Cb<Array<Maybe<ActorRow>>>) getRowsByNames( names ).toAsync( done );

    /**
      * from an Array of names, get an Array of ActorRows, creating those that don't exist
      */
    public function cogRowsFromNames(names : Array<String>):ArrayPromise<ActorRow> {
        // create list to hold all the steps
        var asyncs:Array<Async<ActorRow>> = new Array();
        // build out the array of steps
        for (name in names) {
            asyncs.push(_cogRow.bind(name, _));
        }
        // create the Promise
        return Promise.create({
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
        }).array();
    }
    public function _cogRowsFromNames(names:Array<String>, done:Cb<Array<ActorRow>>) cogRowsFromNames( names ).toAsync( done );

    public function allRows():ArrayPromise<ActorRow> return all();
    public function _allRows(done : Cb<Array<ActorRow>>) allRows().toAsync( done );

    /**
      * get row by id
      */
    public function getRowByName(name : String):Promise<Maybe<ActorRow>> {
        return getBy('name', name);
    }
    public function _getRowByName(name:String, cb:Cb<Maybe<ActorRow>>):Void getRowByName(name).toAsync( cb );

    public function getRowById(id : String):Promise<Maybe<ActorRow>> {
        return getById( id );
    }
    public function _getRowById(id:String, cb:Cb<Maybe<ActorRow>>) getRowById( id ).toAsync( cb );

    public function insertRow(row : ActorRow):Promise<ActorRow> return insert( row );
    public function _insertRow(row:ActorRow, done:Cb<ActorRow>) insert(row).toAsync( done );
    public function putRow(row:ActorRow):Promise<ActorRow> {
        return put(function(q:Query) {
            if (row._id != null)
                return q.eq('_id', row._id);
            else return q.eq('name', row.name);
        }, row);
    }
    public function _putRow(row:ActorRow, done:Cb<ActorRow>) putRow( row ).toAsync( done );
    public function _cogRow(name:String, done:Cb<ActorRow>):Void {
        function newRow():ActorRow {
            return {
                name: name
            };
        }
        _cog(fn(_.eq('name', name)), newRow, null, done);
    }
    public function cogRow(name : String):Promise<ActorRow> {
        return _cogRow.bind(name, _).toPromise();
    }

    public function hasRowForName(name : String):BoolPromise {
        return getRowByName( name ).transform.fn( _.exists ).bool();
    }
    public function _hasRowForName(name:String, done:Cb<Bool>) return hasRowForName( name ).toAsync( done );

    public function allActors():ArrayPromise<Actor> return aprta(allRows());
    public function getActorByName(name : String):Promise<Maybe<Actor>> return prta(getRowByName(name));
    public function getActorById(id : String):Promise<Maybe<Actor>> return prta(getRowById(id));
    public function insertActor(actor:Actor):Promise<Actor> return prta(untyped insertRow(actor.toRow()));
    public function putActor(actor:Actor):Promise<Actor> return prta(untyped putRow(actor.toRow()));
    public function cogActor(name : String):Promise<Actor> return prta(untyped cogRow( name ));
    public function cogActorsFromNames(names : Array<String>):ArrayPromise<Actor> return aprta(untyped cogRowsFromNames( names ));

    public function _allActors(done:Cb<Array<Actor>>) pta(done, allActors());
    public function _getActorByName(name:String, done:Cb<Maybe<Actor>>) pta(done, getActorByName( name ));
    public function _getActorById(id:String, done:Cb<Maybe<Actor>>) pta(done, getActorById( id ));
    public function _insertActor(actor:Actor, done:Cb<Actor>) pta(done, insertActor( actor ));
    public function _putActor(actor:Actor, done:Cb<Actor>) pta(done, putActor( actor ));
    public function _cogActor(name:String, done:Cb<Actor>) pta(done, cogActor( name ));
    public function _cogActorsFromNames(names:Array<String>, done:Cb<Array<Actor>>) pta(done, cogActorsFromNames( names ));

    private function pta<T>(callback:Cb<T>, promise:Promise<T>):Void promise.toAsync( callback );
    private function prta(p : Promise<Maybe<ActorRow>>):Promise<Maybe<Actor>> return p.transform( mrta );
    private function aprta(p : ArrayPromise<Maybe<ActorRow>>):ArrayPromise<Maybe<Actor>> return p.map( mrta );
    private function mrta(row : Maybe<ActorRow>):Maybe<Actor> return row.ternary(rta( _ ), null);
    private function rta(row : ActorRow):Actor return Actor.fromRow( row );

/* === Instance Fields === */
}

typedef ActorRow = {
    ?_id : String,
    name : String
};
