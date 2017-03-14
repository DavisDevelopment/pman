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
    public function tos(table:EitherType<String, Array<String>>, ?mode:String, ?tmp:String):ObjectStore {
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

/* === Computed Instance Fields === */

    public var db(get, never):Database;
    private inline function get_db():Database return dbr.db;

    //public var main(get, never):BPlayerMain;
    //private inline function get_main():BPlayerMain return dbr.app;

/* === Instance Fields === */

    public var dbr : PManDatabase;
}
