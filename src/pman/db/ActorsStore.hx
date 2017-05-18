package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.async.*;
import pman.media.info.Actor;

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

class ActorsStore extends TableWrapper {
    /* Constructor Function */
    public function new(dbr : PManDatabase):Void {
        super( dbr );
    }

/* === Instance Methods === */

    /**
      * write [row] onto the database
      */
    public function putActorRow(row : ActorRow):Promise<ActorRow> {
        return cast put('actors', row);
    }

    /**
      * non-promise putActorRow
      */
    public function putActorRow_(row:ActorRow, ?done:Cb<ActorRow>):Void {
        if (done == null)
            done = untyped fn([e,v]=>null);
        var p = putActorRow( row );
        p.then(function( row ) {
            done(null, row);
        });
        p.unless(function( error ) {
            done(error, null);
        });
    }

    /**
      * write row built from Actor object onto database
      */
    public function addActor(actor:Actor, ?done:Cb<ActorRow>):Void {
        putActorRow_(actor.toRow(), done);
    }

    /**
      * create a new Actor instance, with the given name, and write it to the database
      */
    public function add(name:String, ?done:Cb<ActorRow>):Void {
        addActor(new Actor(name, null, null), done);
    }

    /**
      * retrieve a row from [this] table by id
      */
    public function getActorRow(id : Int):Promise<Null<ActorRow>> {
        return untyped tos('actors').get( id );
    }

    /**
      * non-promise getActorRow
      */
    public function getActorRow_(id:Int, done:Cb<ActorRow>):Void {
        getActorRow( id ).then(done.yield()).unless(done.raise());
    }

    /**
      * get an actor row by id, as an Actor instance
      */
    public function getActor(id : Int):Promise<Null<Actor>> {
        return getActorRow( id ).transform.fn(_ != null ? Actor.fromRow(_) : null);
    }

    /**
      * non-promise getActor
      */
    public function getActor_(id:Int, done:Cb<Actor>):Void {
        getActor( id ).then(done.yield()).unless(done.raise());
    }

    /**
      * get actor row by name
      */
    public function getActorRowByName(name : String):Promise<Null<ActorRow>> {
        return untyped select('tags', {
            name: name
        });
    }

    /**
      * non-promise getActorRowByName
      */
    public function getActorRowByName_(name:String, done:Cb<ActorRow>):Void {
        getActorRowByName( name ).then(done.yield()).unless(done.raise());
    }

    /**
      * create or retrieve a row from [this] table
      */
    public function cogActorRow(name:String, done:Cb<ActorRow>):Void {
        getActorRowByName_(name, function(?err, ?row) {
            if (err != null)
                done(err);
            else if (row != null)
                done(null, row);
            else {
                add(name, function(?err, ?row) {
                    if (err != null)
                        done(err);
                    else
                        done(null, row);
                });
            }
        });
    }

    // get all tag rows
    public function getAllActorRows():ArrayPromise<ActorRow> {
        return Promise.create({
            @forward (untyped tos('actors').getAll());
        }).array();
    }
    public function getAllActorRows_(done : Cb<Array<ActorRow>>):Void {
        getAllActorRows().then(done.yield()).unless(done.raise());
    }

/* === Instance Fields === */
}

typedef ActorRow = {
    ?id: Int,
    name: String,
    ?gender: Int
};
