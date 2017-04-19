package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;

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
    public function putTagRow_(row:TagRow, f:Null<Dynamic>->Null<TagRow>->Void):Void {
        var p = putTagRow( row );
        p.then(function( row ) {
            f(null, row);
        });
        p.unless(function( error ) {
            f(error, null);
        });
    }

    /**
      * retrieve a row from [this] table
      */
    public function getTagRow(name : String):Promise<Null<TagRow>> {
        return untyped tos('tags').get( name );
    }
    public function getTagRow_(name:String, f:Null<Dynamic>->Null<TagRow>->Void):Void {
        var p = getTagRow( name );
        p.then(function(row : Null<TagRow>) {
            f(null, row);
        });
        p.unless(function(error : Dynamic) {
            f(error, null);
        });
    }

    /**
      * create or retrieve a row from [this] table
      */
    public function cogTagRow(name : String):Promise<TagRow> {
        return Promise.create({
            getTagRow_(name, function(error:Null<Dynamic>, row:Null<TagRow>) {
                if (error != null) {
                    throw error;
                }
                else {
                    if (row == null) {
                        @forward putTagRow({
                            name: name,
                            type: ''
                        });
                    }
                    else {
                        return row;
                    }
                }
            });
        });
    }

    /**
      * remove a tag from the database
      */
    /*
    public function deleteTagRow(name:String):BoolPromise {
        return Promise.create({
            var store = tos('tags', 'readwrite');
            store.delete(name, function(error:Null<Dynamic>) {
                if (error != null) {
                    throw error;
                }
                else {

                }
            });
        }).bool();
    }
    */

/* === Instance Fields === */
}

typedef TagRow = {
    name: String,
    type: String,
    ?data: String
};
