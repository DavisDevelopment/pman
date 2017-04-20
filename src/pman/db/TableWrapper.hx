package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.nore.ORegEx;

import ida.*;

import pman.core.*;
import pman.media.*;
import pman.async.*;

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
        ops = new Ops();
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
      * PUT
      */
    public function put<T>(tableName:String, row:T):Promise<T> {
        return Promise.create({
            var store = tos(tableName, 'readwrite');
            var idp = store.put( row ).transform.fn(cast(_, Int));
            idp.then(function(row_id : Int) {
                @forward store.get( row_id ).transform.fn(cast _);
            });
            idp.unless(function(error : Null<Dynamic>) {
                if (error != null) {
                    throw error;
                }
            });
        });
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

    /**
      * perform filter operation, but return the first match
      */
    public function find<T>(tableName:String, test:T->Bool):Promise<T> {
        return Promise.create({
            var result:Null<T> = null;
            var transaction = db.transaction(tableName, 'readonly');
            transaction.complete.once(function() {
                return result;
            });
            var o = transaction.objectStore( tableName );
            var cw = o.openCursor(function(c, w) {
                if (c.entry != null && result == null && test(untyped c.entry)) {
                    result = untyped c.entry;
                    w.abort();
                }
                c.next();
            });
        });
    }
    
    /**
      * iterate over the given Table, deleting every row for which [text] returns 'true'
      */
    public function deleteWheref<T>(tableName:String, test:T->Bool, done:VoidCb):Void {
        var tr = db.transaction(tableName, 'readwrite');
        tr.complete.once(function() {
            done();
        });
        var o = tr.objectStore( tableName );
        var cw = o.openCursor(function(c, w) {
            // if the cursor is currently 'over' a row, and [test] returned 'true' for that row
            if (c.entry != null && test(untyped c.entry)) {
                //TODO delete c.entry;
                trace( c.entry );
            }
            c.next();
        });
    }

    /**
      * SELECT WHERE query
      */
    public function selectAll<T>(tableName:String, query:Dynamic):ArrayPromise<T> {
        var selecter = _selecter( query );
        return cast filter(tableName, selecter);
    }

    public function select<T>(tableName:String, query:Dynamic):Promise<Null<T>> {
        return cast find(tableName, _selecter( query ));
    }

    private function _selecter(query : Dynamic):Object->Bool {
        return (Std.is(query, String) ? _selecterFromORegex(cast query) : _selecterFromObject(new Object( query )));
    }

    /**
      * build selecter lambda from ORegEx string
      */
    private function _selecterFromORegex(oreg : String):Object->Bool {
        var cf = ORegEx.compile(oreg);
        return (function(row : Object) {
            return cf( row );
        });
    }

    /**
      * build filter function for SELECT query
      */
    private function _selecterFromObject(query : Object):Object->Bool {
        var tests:Array<Object->Bool> = new Array();
        for (key in query.keys) {
            var test = _selectTest(key, query[key]);
            tests.push( test );
        }

        if (tests.length > 0) {
            // currently only supports AND chaining
            return (function(row : Object):Bool {
                var res:Bool = false;
                for (test in tests) {
                    if (!test( row )) {
                        return false;
                    }
                }
                return true;
            });
        }
        else {
            return (function(row) return false);
        }
    }

    /**
      * build 'tester' function
      */
    private function _selectTest(key:String, value:Dynamic):Object->Bool {
        // manual lambda test
        if (Reflect.isFunction( value )) {
            return (function(row : Object):Bool {
                return value(row.get( key ));
            });
        }
        else if ((value is QueryOperator)) {
            var op:QueryOperator = cast value;
            switch ( op ) {
                case OpEquals( value ):
                    return (function(row : Object) {
                        return (row.get(key) == value);
                    });

                case OpNEquals( value ):
                    return (function(row : Object) {
                        return (row.get(key) != value);
                    });

                case OpContains( value ):
                    return (function(row : Object) {
                        var col:Dynamic = row.get( key );
                        if ((col is Array<Dynamic>)) {
                            return cast(col, Array<Dynamic>).has( value );
                        }
                        else if ((col is String)) {
                            return cast(col, String).has(Std.string( value ));
                        }
                        else {
                            throw 'TypeError: Invalid "contains" operation';
                        }
                    });
            }
        }
        else {
            return (function(row : Object) {
                return (row[key] == value);
            });
        }
    }

/* === Computed Instance Fields === */

    public var db(get, never):Database;
    private inline function get_db():Database return dbr.db;

    //public var main(get, never):BPlayerMain;
    //private inline function get_main():BPlayerMain return dbr.app;

/* === Instance Fields === */

    public var dbr : PManDatabase;
    public var ops : Ops;
}

typedef TransactionKey = EitherType<String, Array<String>>;

class Ops {
    public function new():Void {

    }

    public function equals<T>(value : T):QueryOperator return OpEquals( value );
    public function nequals<T>(value : T):QueryOperator return OpNEquals( value );
    public function contains<T>(value : T):QueryOperator return OpContains( value );
}

enum QueryOperator {
    OpEquals<T>(value : T);
    OpNEquals<T>(value : T);
    OpContains<T>(value : T);
}
