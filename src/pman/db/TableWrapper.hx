package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;

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

class TableWrapper {
    /* Constructor Function */
    public function new(db_root:PManDatabase):Void {
        dbr = db_root;
    }

/* === Instance Methods === */

    /**
      * get a usable reference to an objectStore
      */
    public function tos(table:TransactionKey, ?mode:String, ?tmp:String):ObjectStore {
        var tableName:String = '';
        if (Std.is(table, String)) {
            tableName = cast table;
        }
        else if ((table is Array<String>)) {
            if (mode != null && tmp != null) {
                tableName = mode;
                mode = tmp;
            }
            else {
                throw 'Error: Invalid argument set';
            }
        }
        return db.transaction(table, mode).objectStore( tableName );
    }

    /**
      * get references to multiple tables with the same mode
      */
    public function tables(names:Array<String>, ?mode:String):Array<ObjectStore> {
        var t = db.transaction(names, mode);
        return names.map.fn(t.objectStore(_));
    }

    /**
      * perform [action] for each row where [test] returns true
      */
    public function walk<T>(table:String, action:T->Void, ?transaction:Transaction, ?test:T->Bool, ?end:Null<Dynamic>->Void):Void {
        var o = (transaction != null ? transaction.objectStore( table ) : tos( table ));
        var cw = o.openCursor(function(c, w) {
            if (c.entry != null) {
                if (test == null || test(untyped c.entry)) {
                    action(untyped c.entry);
                }
            }
        });
        if (end != null) {
            cw.error.once(function(err) end( err ));
            cw.complete.once(function() end( null ));
        }
    }

    /**
      * perform a filter operation
      */
    public function filter<T>(tableName:String, f:T->Bool):ArrayPromise<T> {
        return Promise.create({
            var results:Array<T> = new Array();
            function done(err : Null<Dynamic>)
                if (err != null)
                    throw err;
                else return results;
            walk(tableName, results.push.bind(_), null, f, done);
        }).array();
    }

/* === Computed Instance Fields === */

    public var db(get, never):Database;
    private inline function get_db():Database return dbr.db;

    //public var main(get, never):BPlayerMain;
    //private inline function get_main():BPlayerMain return dbr.app;

/* === Instance Fields === */

    public var dbr : PManDatabase;
}

typedef TransactionKey = EitherType<String, Array<String>>;
