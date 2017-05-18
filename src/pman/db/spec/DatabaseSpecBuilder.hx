package pman.db.spec;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.nore.ORegEx;

import ida.*;

import pman.async.*;

import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class DatabaseSpecBuilder {
    /* Constructor Function */
    public function new(spec : DatabaseSpec):Void {
        this.spec = spec;
    }

/* === Instance Methods === */

    /**
      * open the database referred to by the given spec
      */
    public function open(done : Cb<Database>):Void {
        var dbp = Database.open(spec.name, spec.version, build);
        dbp.then(done.yield()).unless(done.raise());
    }

    /**
      * build out the given database to [this]'s specification
      */
    public function build(database : Database):Void {
        d = database;
        for (tableSpec in spec.tables) {
            buildTable( tableSpec );
        }
    }

    /**
      * build a new table to the given spec
      */
    private function buildTable(ts : TableSpec):Void {
        if (d.hasObjectStore( ts.name )) {
            d.deleteObjectStore( ts.name );
        }

        var t = d.createObjectStore(ts.name, {
            keyPath: ts.primaryKey,
            autoIncrement: ts.autoIncrement
        });
		inline function i(n, k, ?o) {
			t.createIndex(n, k, o);
		}
		for (tis in ts.indices) {
		    i(tis.name, tis.name, {
                unique: tis.unique
		    });
		}
    }

/* === Instance Fields === */

    public var spec : DatabaseSpec;
    public var d : Database;
}
