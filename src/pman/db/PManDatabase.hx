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

class PManDatabase {
	/* Constructor Function */
	public function new():Void {
		//app = main;

		or = new VoidSignal();
		or.once(function() reddy = true);

		configInfo = new ConfigInfo( this );
		mediaStore = new MediaStore( this );
	}

/* === Instance Methods === */

	/**
	  * Get a media entry by its uri/id
	  */
	/*
	public function getMediaRow(key : EitherType<String, Int>):Promise<Null<MediaRow>> {
		return Promise.create({
		    if (Std.is(key, Int)) {
		        var id:Int = cast key;
                function query():Void {
                    var p = tl('media_items').get( id );
                    p.unless(function(error) {
                        console.error( error );
                        throw error;
                    });
                    p.then(function( row ) {
                        return row;
                    });
                }
                onready( query );
		    }
            else if (Std.is(key, String)) {
                var uri:String = cast key;
                var row:Null<Dynamic> = null;
                function search(cursor:Cursor, walker) {
                    trace( cursor.entry );
                    if (cursor.entry != null) {
                        var ro = cursor.entry;
                        if (ro.uri == uri) {
                            walker.abort();
                            return untyped ro;
                        }
                    }
                }
                trace('starting cursor iteration');
                var c = tl('media_items').openCursor( search );
                c.complete.once(function() {
                    trace('cursor iteration complete');

                });
                c.error.once(function(err) {
                    trace('Error: $err');
                });
            }
            else {
                throw 'fuck me';
            }
		});
	}
	*/

	/**
	  * create/update the given row
	  */
	/*
	public function putMediaRow(row : MediaRow):Promise<MediaRow> {
		return Promise.create({
			function query() {
				var table = tl('media_items', 'readwrite');
				var p = table.put( row );
				p.unless(function(error) {
					console.error( error );
					throw error;
				});
				p.then(function(id : Int) {
					@forward getMediaRow( id );
				});
			}
			onready( query );
		});
	}
	*/

	/**
	  * attempt to get the MediaRow for the given Track
	  -- if successful, yield that
	  -- if unsuccessful, create new MediaRow for that Track,
	     PUT it onto the table, and yield the result of that action
	  */
	/*
	public function cogMediaRow(track : Track):Promise<MediaRow> {
		return Promise.create({
			var uri:String = track.provider.getURI();
			var p = getMediaRow( uri );
			p.unless(function(error) {
				console.error( error );
				throw error;
			});
			p.then(function(result : Null<MediaRow>):Void {
				if (result != null) {
					return result;
				}
				else {
					// create the new MediaRow
					var row:MediaRow = {
						uri: uri
					};
					@forward putMediaRow( row );
				}
			});
		});
	}
	*/

	/**
	  * push the given MediaRow onto the database (simplified)
	  -- no Promises to deal with or return values to worry about
	     just a nice Boolean callback to let you know whether the push
	     was successful
	  */
	/*
	public function pushMediaRow(row:MediaRow, done:Bool->Void):Void {
		var p = putMediaRow( row );
		p.then(function(nrow : MediaRow) {
			done( true );
		});
		p.unless(function(error) {
			console.error( error );
			done( false );
		});
	}
	*/

	/**
	  * a super-simplified pull/modify/push operation method
	  */
	/*
	public function editMediaRow(track:Track, edit:MediaRow->MediaRow, done:MediaRow->Void):Void {
		var p = cogMediaRow( track );
		p.unless( rat ).then(function(row : MediaRow) {
			row = edit( row );
			p = putMediaRow( row );
			p.unless( rat ).then( done );
		});
	}
	*/

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

		var p = Database.open(DBNAME, DBVERSION, build_db);
		p.then(function( db ) {
			this.db = db;

			or.fire();
		});
		p.unless(function( error ) {
			throw error;
		});
	}

/* === Database-Creation Methods === */

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
	    i('rating', 'rating');
	    i('favorite', 'favorite');
	    i('time', 'time');
	    i('tags', 'tags');
	    i('actors', 'actors');
	}

    /**
      * build the 'tags' table
      */
	private function build_tagsTable(db : Database):Void {
	    var tags = db.createObjectStore('tags', {
            keyPath: 'name'
            //autoIncrement: true
	    });
	    inline function i(n, k, ?o) tags.createIndex(n,k,o);
		//i('id', 'id', {unique: true});
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
	public var db : Database;
	public var configInfo : ConfigInfo;
	public var mediaStore : MediaStore;

	private var or : VoidSignal;
	private var reddy : Bool = false;

/* === Static Fields === */

	private static inline var DBNAME:String = 'pman';
	private static inline var DBVERSION:Int = 1;
}

