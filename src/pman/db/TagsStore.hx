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
        return Promise.create({
            var store = tos('tags', 'readwrite');
            var idp = store.put( row ).transform.fn(cast(_, String));
            idp.then(function(name : String) {
                @forward store.get( name ).transform.fn(cast _);
            });
            idp.unless(function(error : Null<Dynamic>) {
                if (error != null) {
                    throw error;
                }
            });
        });
    }

    /**
      * retrieve a row from [this] table
      */
    public function getTagRow(name : String):Promise<TagRow> {
        return Promise.create({
            var store = tos('tags');
            return store.get( name ).transform.fn(cast _);
        });
    }

    /**
      * 
      */

/* === Instance Fields === */
}

typedef TagRow = {
    name: String,
    ?type: String,
    ?data: String
};
