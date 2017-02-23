package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import electron.ext.*;

import pman.core.*;
import pman.core.PlayerSession;
import pman.media.*;

import foundation.Tools.*;
import tannus.math.TMath.*;

import haxe.Json;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class AppDir {
	/* Constructor Function */
	public function new(app : BPlayerMain):Void {
		main = app;
	}

/* === Instance Methods === */

	/**
	  * get the Path to [this]
	  */
	public inline function path():Path {
		return App.getPath( UserData );
	}

	/**
	  * get the directory object itself
	  */
	public inline function dir():Directory {
		return new Directory(path());
	}

	/**
	  * check whether there is a saved session
	  */
	public function hasSavedSession():Bool {
		return Fs.exists(path().plusString('session.json'));
	}

	/**
	  * get the saved session 
	  */
	public function loadSession():Null<JsonSession> {
		var sessPath:Path = path().plusString( 'session.json' );
		if (Fs.exists( sessPath )) {
			var text = Fs.read( sessPath ).toString();
			var data:JsonSession = Json.parse( text );
			return data;
		}
		else {
			return null;
		}
	}

	/**
	  * save a Session
	  */
	public function saveSession(session : JsonSession):Void {
		var sessPath:Path = path().plusString( 'session.json' );
		var data = ByteArray.ofString(Json.stringify(session, null, '   '));
		Fs.write(sessPath, data);
	}

/* === Instance Fields === */

	public var main : BPlayerMain;
}
