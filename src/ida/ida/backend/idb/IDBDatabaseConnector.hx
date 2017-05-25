package ida.backend.idb;

import tannus.ds.*;
import tannus.html.Win;
import tannus.html.fs.*;

import js.html.idb.*;
import haxe.extern.EitherType in Either;

import ida.Utils;

using Lambda;

class IDBDatabaseConnector {
    /* Constructor Function */
    public function new(name:String, version:Int, ?_build:IDBDatabase->Void):Void {
        openInfo = {name:name, version:version, build:_build};
        conn = null;
    }

/* === Instance Methods === */

    /**
      * request a connection to the database
      */
    public function connect(f : ConnBody):Void {
        function dun():Void {
            openCount--;
            if (openCount == 0) {
                conn.close();
                conn = null;
                trace('active connection closed');
            }
        }

        if (conn != null) {
            openCount++;
            f(conn, dun);
        }
        else {
            _open(function(db : IDBDatabase) {
                this.conn = db;
                openCount++;
                f(db, dun);
            });
        }
    }

    /**
      * open the database
      */
    private function _open(cb : IDBDatabase->Void):Void {
        var i = openInfo;
        var p = IDBDatabase.open(i.name, i.version, i.build);
        p.then( cb );
        p.unless(function(error : Dynamic) {
            throw error;
        });
    }

/* === Instance Fields === */

    private var openInfo : OpenInfo;
    private var conn : Null<IDBDatabase>;
    private var openCount : Int = 0;
}

@:callable
abstract ConnBody (IDBDatabase->(Void->Void)->Void) from IDBDatabase->(Void->Void)->Void {
    public inline function new(f : IDBDatabase->(Void->Void)->Void):Void {
        this = f;
    }
}

private typedef OpenInfo = {
    name: String,
    version: Int,
    ?build: IDBDatabase->Void
};
