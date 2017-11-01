package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;
import pman.edb.Query;
import pman.edb.Modification;
import pman.edb.Query.*;

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
using tannus.html.JSTools;

typedef TableWrapper = edis.storage.db.TableWrapper;

class TableWrapper_ {
    /* Constructor Function */
    public function new(root:PManDatabase, store:DataStore):Void {
        this.root = root;
        this.store = store;
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    public function init(done : VoidCb):Void {
        store.loadDatabase( done );
    }

    /**
      * run a Query
      */
    public function query<T>(query : QueryDecl):ArrayPromise<T> {
        return find(query.toDynamic()).array();
    }
    public function _query<T>(query:QueryDecl, done:Cb<Array<T>>) {
        this.query(query).toAsync( done );
    }

    /**
      * run a Query
      */
    public function queryOne<T>(query : QueryDecl):Promise<T> {
        return findOne(query.toDynamic());
    }
    public function _queryOne<T>(query:QueryDecl, done:Cb<T>):Void {
        queryOne(query).toAsync( done );
    }

    /**
      * get the single item that matches [query]
      */
    public function findOne<T>(query:Dynamic):Promise<Maybe<T>> {
        return store.findOne.bind(query, _).toPromise();
    }
    public function _findOne<T>(q:Dynamic, f:Cb<Maybe<T>>):Void {
        findOne(q).toAsync( f );
    }

    /**
      * get all items taht match [query]
      */
    public function find<T>(query:Dynamic):Promise<Array<T>> {
        return untyped store.find.bind(query, _).toPromise();
    }
    public function _find<T>(q:Dynamic, f:Cb<T>):Void {
        find(q).toAsync(untyped f);
    }

    /**
      * get all items in [this] table
      */
    public function all<T>():ArrayPromise<T> {
        return find({}).array();
    }
    public function _all<T>(done : Cb<Array<T>>):Void {
        all().toAsync( done );
    }

    /**
      * get all by a single field
      */
    public function getAllBy<T>(index:String, value:Dynamic):ArrayPromise<T> {
        return find(_bo(function(o : Object) {
            o[index] = value;
        })).array();
    }
    public function _getAllBy<T>(index:String, value:Dynamic, done:Cb<Array<T>>):Void {
        getAllBy(index, value).toAsync( done );
    }

    /**
      * get a single row by a single field
      */
    public function getBy<T>(index:String, value:Dynamic):Promise<T> {
        return findOne(_bo(function(o : Object) {
            o[index] = value;
        }));
    }
    public function _getBy<T>(index:String, value:Dynamic, done:Cb<T>):Void {
        return getBy(index, value).toAsync( done );
    }

    /**
      * get an item by id
      */
    public function getById<T>(id : Dynamic):Promise<T> {
        return getBy('_id', id);
    }
    public function _getById<T>(id:Dynamic, done:Cb<T>):Void {
        getById(id).toAsync( done );
    }

    /**
      * update an item
      */
    public function update<T>(query:Dynamic, update:Dynamic, ?options:{?multi:Bool,?insert:Bool}):Promise<T> {
        return Promise.create({
            store.update(query, update, buildUpdateOptions(options), function(err:Null<Dynamic>, numAffected:Int, affectedDocuments:T, upsert:Bool) {
                if (err != null) {
                    throw err;
                }
                else {
                    return affectedDocuments;
                }
            });
        });
    }
    public function _update<T>(query:Dynamic, update:Dynamic, ?options:{?multi:Bool, ?insert:Bool}, done:Cb<T>):Void {
        this.update(query, update, options).toAsync( done );
    }

    /**
      * modify an item
      */
    public function mutate<T>(query:QueryDecl, mod:Mod, ?options:{?multi:Bool, ?insert:Bool}):Promise<T> {
        return Promise.create({
            var p = update(query.toObject(), mod.toObject(), options);
            p.then(function(o : Object) {
                @forward getById(o['_id']);
            });
            p.unless(function(error) {
                throw error;
            });
        });
    }
    public function _mutate<T>(query:QueryDecl, mod:Mod, ?options:{?multi:Bool,?insert:Bool}, done:Cb<T>):Void {
        mutate(query, mod, options).toAsync( done );
    }

    /**
      * put an item
      */
    public function put<T>(query:QueryDecl, update:Dynamic):Promise<T> {
        if (update.nag('_id') == null) {
            update.nad('_id');
        }

        return this.update(query.toObject(), update, {
            multi: false,
            insert: true
        });
    }
    public function _put<T>(query:QueryDecl, update:Dynamic, done:Cb<T>):Void {
        put(query, update).toAsync( done );
    }

    /**
      * insert an item
      */
    public function insert<T>(doc : Dynamic):Promise<T> {
        if (doc.nag('_id') == null) {
            doc.nad('_id');
        }
        return store.insert.bind(doc, _).toPromise();
    }
    public function _insert<T>(doc:Dynamic, done:Cb<T>) insert(doc).toAsync( done );

    /**
      * create a new Index
      */
    public function createIndex(fieldName:String, unique:Bool=false, sparse:Bool=false, ?done:VoidCb):Void {
        store.ensureIndex({
            fieldName: fieldName,
            unique: unique,
            sparse: sparse
        }, done);
    }

    /**
      * delete an Index
      */
    public function deleteIndex(fieldName:String, ?done:VoidCb):Void {
        store.removeIndex(fieldName, done);
    }

    /**
      * create a new Row
      */
    public function create<T>(row : T):Promise<T> {
        return insert( row );
    }
    public function _create<T>(row:T, done:Cb<T>) create( row ).toAsync( done );

    /**
      * fetch, or create, a row
      */
    public function _cog<T>(query:QueryDecl, fresh:Void->T, ?test:T->Bool, done:Cb<T>):Void {
        _queryOne(query, function(?error, ?row:Maybe<T>) {
            if (error != null) {
                return done(error, null);
            }
            else if (row != null && (test == null || test( row ))) {
                return done(null, row);
            }
            else {
                _create(fresh(), done);
            }
        });
    }
    public function cog<T>(query:QueryDecl, fresh:Void->T, ?test:T->Bool):Promise<T> {
        return _cog.bind(query, fresh, test, _).toPromise();
    }

    /**
      * delete one or more documents
      */
    public function remove<T>(query:QueryDecl, done:EitherType<VoidCb, Cb<Int>>, multiple:Bool=false):Void {
        store.remove(query.toDynamic(), {multi:multiple}, function(?error, ?numRemoved) {
            untyped done(error, numRemoved);
        });
    }

/* === Utility Methods === */

    public inline function createModification():Modification return new Modification();
    public inline function createQuery():Query return new Query();

    /**
      * build out the update options
      */
    private function buildUpdateOptions(?o : {?multi:Bool, ?insert:Bool}):UpdateOptions {
        o = us.defaults((o != null ? o : {}), {
            multi: false,
            insert: true
        });
        return {
            multi: o.multi,
            upsert: o.insert,
            returnUpdatedDocs: true
        };
    }

    /**
      * utility method to construct an Object
      */
    private function _buildObject(f : Object->Void):Object {
        var o:Object = {};
        f( o );
        return o;
    }
    private inline function _bo(f : Object->Void):Object return _buildObject( f );

/* === Instance Fields === */

    public var root : PManDatabase;
    public var store : DataStore;
}
