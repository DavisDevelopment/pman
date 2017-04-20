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
            done = untyped fn([e=null,v=null]=>null);
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
        addTag(new Tag(name, type), done);
    }

    /**
      * retrieve a row from [this] table
      */
    public function getTagRow(name : String):Promise<Null<TagRow>> {
        return untyped tos('tags').get( name );
    }
    public function getTagRow_(name:String, done:Cb<TagRow>):Void {
        getTagRow( name ).then( done ).unless( done );
    }
    public function getTag(name : String):Promise<Null<Tag>> {
        return getTagRow( name ).transform.fn(_ != null ? Tag.fromRow(_) : null);
    }
    public function getTag_(name:String, done:Cb<Tag>):Void {
        getTag( name ).then(done).unless(done);
    }

    /**
      * create or retrieve a row from [this] table
      */
    public function cogTagRow(name:String, ?type:TagType):Promise<TagRow> {
        return Promise.create({
            getTagRow_(name, function(?error:Dynamic, ?row:TagRow) {
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

/* === Instance Fields === */
}

typedef TagRow = {
    name: String,
    type: String,
    ?data: String
};
