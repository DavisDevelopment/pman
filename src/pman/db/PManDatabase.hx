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

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PManDatabase {
	/* Constructor Function */
	public function new(main : BPlayerMain):Void {
		app = main;

		or = new VoidSignal();
		or.once(function() reddy = true);
	}

/* === Instance Methods === */

	/**
	  * Get a media entry by its uri/id
	  */
	public function getMediaRow(uri : String):Promise<Null<MediaRow>> {
		return Promise.create({
			function query() {
				var p = tl('media').get( uri );
				p.unless(function(error) {
					console.error( error );
					throw error;
				});
				p.then(function(row) {
					return row;
				});
			}
			onready( query );
		});
	}

	/**
	  * create/update the given row
	  */
	public function putMediaRow(row : MediaRow):Promise<MediaRow> {
		return Promise.create({
			function query() {
				var table = tl('media', 'readwrite');
				var p = table.put( row );
				p.unless(function(error) {
					console.error( error );
					throw error;
				});
				p.then(function(uri : Dynamic) {
					@forward getMediaRow(cast uri);
				});
			}
			onready( query );
		});
	}

	/**
	  * attempt to get the MediaRow for the given Track
	  -- if successful, yield that
	  -- if unsuccessful, create new MediaRow for that Track,
	     PUT it onto the table, and yield the result of that action
	  */
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
						uri: uri,
						title: track.title,
						views: 0,
						starred: false,
						timing: {
							duration : null,
							last_time : null
						}
					};
					@forward putMediaRow( row );
				}
			});
		});
	}

	/**
	  * push the given MediaRow onto the database (simplified)
	  -- no Promises to deal with or return values to worry about
	     just a nice Boolean callback to let you know whether the push
	     was successful
	  */
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

	/**
	  * a super-simplified pull/modify/push operation method
	  */
	public function editMediaRow(track:Track, edit:MediaRow->MediaRow, done:MediaRow->Void):Void {
		var p = cogMediaRow( track );
		p.unless( rat ).then(function(row : MediaRow) {
			row = edit( row );
			p = putMediaRow( row );
			p.unless( rat ).then( done );
		});
	}

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

	/**
	  * construct the database
	  */
	private function build_db(db : Database):Void {
		var media = db.createObjectStore('media', {
			keyPath: 'uri'
		});
		inline function i(n, k, ?o) {
			media.createIndex(n, k, o);
		}

		i('uri', 'uri', {
			unique: true
		});
		i('title', 'title');
		i('views', 'views');
		i('starred', 'starred');

		i('timing', 'timing');
		//i('duration', 'timing/duration');
		//i('last_time', 'timing/last_time');
	}

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

	public var app : BPlayerMain;
	public var db : Database;

	private var or : VoidSignal;
	private var reddy : Bool = false;

/* === Static Fields === */

	private static inline var DBNAME:String = 'pman';
	private static inline var DBVERSION:Int = 1;
}

typedef MediaRow = {
	uri : String,
	title : String,
	views : Int,
	starred : Bool,
	timing : {
		duration : Null<Float>,
		last_time : Null<Float>
	}
};
