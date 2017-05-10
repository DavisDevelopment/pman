package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;

import pman.core.*;
import pman.media.*;
import pman.db.spec.*;

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

class PManDatabase {
	/* Constructor Function */
	public function new():Void {
		//app = main;

		or = new VoidSignal();
		or.once(function() reddy = true);

		configInfo = new ConfigInfo( this );
		mediaStore = new MediaStore( this );
		tagsStore = new TagsStore( this );
		preferences = Preferences.pull();
	}

/* === Instance Methods === */

	/**
	  * wait for [this] to be ready, and invoke [action]
	  */
	public inline function onready(action : Void->Void):Void {
		(reddy ? defer : or.once)( action );
	}

	/**
	  * initialize
	  */
	public function init(?done : Void->Void):Void {
		if (done != null) {
			onready( done );
		}

        /*
		var p = Database.open(DBNAME, DBVERSION, build_db);
		p.then(function( db ) {
			this.db = db;

			defer( or.fire );
		});
		p.unless(function( error ) {
			throw error;
		});
		*/
	}

/* === Database-Creation Methods === */

    /**
      * construct the database layout specification
      */
    private function build_spec():Void {
        /* test db spec system */
        dbspec = new DatabaseSpec( DBNAME );

        // media_items table
        var t = dbspec.addTable('media_items');
        t.addIndices([
            'id' => {primary: true},
            'uri' => null
        ]);
        t.autoIncrement = true;

        // media_info table
        t = dbspec.addTable('media_info');
        t.addIndices([
            'id' => {primary: true},
            'views'=>null,'duration'=>null,'marks'=>null,
            'tags'=>null,'actors'=>null,'meta'=>null
        ]);

        // tags table
        t = dbspec.addTable('tags');
        t.addIndices([
            'id' => {primary: true},
            'name' => {unique: true},
            'type' => null
        ]);
        t.autoIncrement = true;

        // actors table
        t = dbspec.addTable('actors');
        t.addIndices([
            'id' => {primary: true},
            'name' => {unique: true},
            'gender' => null
        ]);
        t.autoIncrement = true;
    }

	/**
	  * construct the database as a whole
	  */
	private function build_db(db : Database):Void {
	    var tablBuilders:Array<Database->Void> = [build_tagsTable, build_actorsTable, build_mediaItemsTable, build_mediaInfoTable];

	    for (f in tablBuilders) {
	        f( db );
	    }
	}

    /**
      * build the 'media_items' table
      */
	private function build_mediaItemsTable(db : Database):Void {
		var media = db.createObjectStore('media_items', {
			keyPath: 'id',
			autoIncrement: true
		});
		inline function i(n, k, ?o) {
			media.createIndex(n, k, o);
		}

        i('id', 'id', {
            unique: true
        });
		i('uri', 'uri', {
			unique: true
		});
	}

    /**
      * build the 'media_info' table
      */
	private function build_mediaInfoTable(db : Database):Void {
	    var info = db.createObjectStore('media_info', {
            keyPath: 'id'
	    });
	    inline function i(n, k, ?o) info.createIndex(n,k,o);
	    // foreign-key reference to media_items.id
	    i('id', 'id', {
            unique: true
	    });
	    i('views', 'views');
	    i('starred', 'starred');
	    i('duration', 'duration');
	    i('marks', 'marks');
	    i('tags', 'tags');
	    i('actors', 'actors');
	    i('meta', 'meta');
	}

    /**
      * build the 'tags' table
      */
	private function build_tagsTable(db : Database):Void {
	    var tags = db.createObjectStore('tags', {
            keyPath: 'id',
            autoIncrement: true
	    });
	    inline function i(n, k, ?o) tags.createIndex(n,k,o);
        i('id', 'id', {unique: true});
	    i('name', 'name', {unique: true});
	    i('type', 'type');
	    i('data', 'data');
	}

    /**
      * build the 'actors' table
      */
	private function build_actorsTable(db : Database):Void {
	    var actors = db.createObjectStore('actors', {
            keyPath: 'id',
            autoIncrement: true
	    });
	    inline function i(n, k, ?o) actors.createIndex(n,k,o);

        i('id', 'id', {unique: true});
        i('name', 'name', {unique: true});
        i('gender', 'gender');
	}

/* === Utility Methods === */

	/**
	  * get a Transaction object
	  */
	private inline function tl(table:String, ?mode:String) {
		return db.transaction(table, mode).objectStore( table );
	}

	// tgp -- (t)hrow (error), (g)et (value of) (p)romise
	private function tgp<T>(p:Promise<T>, f:T->Void):Void {
		p.unless(function(error) {
			js.Browser.console.error( error );
			throw error;
		}).then( f );
	}

	// RAT -- Report and Throw
	private function rat(error : Dynamic):Void {
		console.error( error );
		throw error;
	}

/* === Instance Fields === */

	//public var app : BPlayerMain;
	public var dbspec : DatabaseSpec;
	public var db : Database;
	public var configInfo : ConfigInfo;
	public var mediaStore : MediaStore;
	public var tagsStore : TagsStore;
	public var preferences : Preferences;

	private var or : VoidSignal;
	private var reddy : Bool = false;

/* === Static Fields === */

	private static inline var DBNAME:String = 'pman';
	private static inline var DBVERSION:Int = 2;
}

