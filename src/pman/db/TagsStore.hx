package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.async.*;
import pman.media.info.Tag;

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

class TagsStore extends TableWrapper {
    /* Constructor Function */
    public function new(dbr : PManDatabase):Void {
        super( dbr );
    }

/* === Instance Methods === */

    /**
      * write [row] onto the database
      */
    public function putTagRow(row : TagRow):Promise<TagRow> {
        return cast put('tags', row);
    }
    public function putTagRow_(row:TagRow, ?done:Cb<TagRow>):Void {
        if (done == null)
            done = untyped fn([e,v]=>null);
        var p = putTagRow( row );
        p.then(function( row ) {
            done(null, row);
        });
        p.unless(function( error ) {
            done(error, null);
        });
    }
    public function addTag(tag:Tag, ?done:Cb<TagRow>):Void {
        putTagRow_(tag.toRow(), done);
    }
    public function add(name:String, ?type:TagType, ?done:Cb<TagRow>):Void {
        addTag(new Tag(name, null, type), done);
    }

    /**
      * retrieve a row from [this] table
      */
    public function getTagRow(id : Int):Promise<Null<TagRow>> {
        return untyped tos('tags').get( id );
    }
    public function getTagRow_(id:Int, done:Cb<TagRow>):Void {
        getTagRow( id ).then(done.yield()).unless(done.raise());
    }
    public function getTag(id : Int):Promise<Null<Tag>> {
        return getTagRow( id ).transform.fn(_ != null ? Tag.fromRow(_) : null);
    }
    public function getTag_(id:Int, done:Cb<Tag>):Void {
        getTag( id ).then(done.yield()).unless(done.raise());
    }
    public function getTagRowByName(name : String):Promise<Null<TagRow>> {
        return untyped select('tags', {
            name: name
        });
    }
    public function getTagRowByName_(name:String, done:Cb<TagRow>):Void {
        getTagRowByName( name ).then(done.yield()).unless(done.raise());
    }

    /**
      * create or retrieve a row from [this] table
      */
    public function cogTagRow(name:String, ?type:TagType, done:Cb<TagRow>):Void {
        getTagRowByName_(name, function(?err, ?row) {
            if (err != null)
                done(err);
            else if (row != null)
                done(null, row);
            else {
                add(name, type, function(?err, ?row) {
                    if (err != null)
                        done(err);
                    else
                        done(null, row);
                });
            }
        });
    }
    public function cogTagRold(name:String, ?type:TagType):Promise<TagRow> {
        return Promise.create({
            getTagRowByName_(name, function(?error:Dynamic, ?row:TagRow) {
                if (error != null)
                    throw error;
                else if (row != null)
                    return row;
                else {
                    add(name, type, function(?error:Dynamic, ?row:TagRow) {
                        if (error != null)
                            throw error;
                        else
                            return row;
                    });
                }
            });
        });
    }

    // get all tag rows
    public function getAllTagRows():ArrayPromise<TagRow> {
        return Promise.create({
            @forward (untyped tos('tags').getAll());
        }).array();
    }
    public function getAllTagRows_(done : Cb<Array<TagRow>>):Void {
        getAllTagRows().then(done.yield()).unless(done.raise());
    }

/* === Instance Fields === */
}

typedef TagRow = {
    id: Int,
    name: String,
    type: String,
    ?data: String
};
