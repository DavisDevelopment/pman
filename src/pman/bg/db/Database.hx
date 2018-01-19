package pman.bg.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import edis.libs.nedb.*;
import edis.storage.db.*;
import edis.core.Prerequisites;

import Slambda.fn;
import edis.Globals.*;

import pman.bg.Dirs;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;

class Database {
    /* Constructor Function */
    public function new(autoInit:Bool=false):Void {
        tables = new Dict();
        reqs = new Prerequisites();
        _or = new OnceSignal();

        if (instance == null) {
            instance = this;
        }

        if ( autoInit ) {
            init();
        }
    }

/* === Instance Methods === */

    /**
      * initialize [this] Database instance
      */
    public function init(?done: VoidCb):Void {
        if (done == null) {
            done = untyped ((?err)->trace( err ));
        }

        _build();

        reqs.meet(function(?error) {
            if (error != null) {
                return done( error );
            }
            else {
                _or.announce();
                done();
            }
        });
    }

    /**
      * check if [this] Database is ready
      */
    public function isReady():Bool {
        return _or.isReady();
    }

    /**
      * wait for [this] Database to be ready
      */
    public function ensure(action: Void->Void):Void {
        return ((isReady() ? defer : _or.on)( action ));

        if (isReady()) {
            defer( action );
        }
        else {
            _or.on( action );
        }
    }
    public inline function onready(f: Void->Void):Void ensure( f );

    /**
      * add to [this]'s requirements
      */
    public function require(task: VoidAsync):Void {
        reqs.vasync( task );
    }

    /**
      * get a new Table
      */
    public function openTable<T:Table>(name:String, ?tableClass:Class<T>):T {
        if (tableClass == null) {
            tableClass = untyped Table;
        }

        if (!name.endsWith('.db')) {
            name += '.db';
        }

        if (!tables.exists( name )) {
            var table:T = Type.createInstance(tableClass, untyped [getStore(name)]);
            tables.set(name, cast table);
            reqs.vasync( table.init );
            return table;
        }
        else {
            return cast tables.get( name );
        }
    }

    /**
      * open up a new DataStore
      */
    private function getStore(name: String):DataStore {
        if (!name.endsWith('.db')) {
            name += '.db';
        }
        if (_stores.exists( name )) {
            return _stores[name];
        }
        else {
            return (_stores[name] = new DataStore({
                filename: Dirs.dbPath( name ).toString()
            }));
        }
    }

    /**
      * build [this] Database instance
      */
    private function _build():Void {
        actors = openTable('actors', ActorTable);
        tags = openTable('tags', TagTable);

        #if !(worker && test)
        media = openTable('media', MediaTable);
        #else
        var mtp = Dirs.dbPath('media.db');
        if (Fs.exists( mtp )) {
            Fs.copy(mtp, mtp.plusString('../media_test.db'));
        }
        media = openTable('media_test', MediaTable);
        #end
    }

/* === Instance Fields === */

    public var media: MediaTable;
    public var actors: ActorTable;
    public var tags: TagTable;

    public var tables: Dict<String, Table>;
    public var reqs: Prerequisites;

    private var _or: OnceSignal;

/* === Static Fields === */

    private static var _stores:Dict<String, DataStore> = {new Dict();};
    public static var instance:Null<Database> = null;

/* === Static Methods === */

    /**
      * obtain a Database object
      */
    public static function get(?safeAction:Database->Void):Database {
        var res:Database = instance;
        if (res == null) {
            res = new Database( true );
        }
        if (safeAction != null) {
            res.ensure(safeAction.bind(res));
        }
        return res;
    }
}
