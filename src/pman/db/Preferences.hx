package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.sys.*;

import ida.*;

import pman.core.*;
import pman.media.*;

import electron.ext.App;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;

import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Preferences {
    /* Constructor Function */
    public function new():Void {
        defaults();
    }

/* === Instance Methods === */

    /**
      * fill [this] object in with its default values
      */
    public function defaults():Void {
        autoPlay = true;
        autoRestore = false;
        directRender = true;
        showAlbumArt = true;
        showSnapshot = true;
        snapshotPath = (App.getPath( Pictures ).plusString('pman_snapshots'));
    }

    /**
      * serialize [this]
      */
    @:keep
    public function hxSerialize(s : Serializer):Void {
        inline function w(x : Dynamic)
            s.serialize( x );

        w( autoPlay );
        w( autoRestore );
        w( directRender );
        w( showAlbumArt );
        w( showSnapshot );
        w(snapshotPath.toString());
    }

    /**
      * unserialize [this]
      */
    @:keep
    public function hxUnserialize(u : Unserializer):Void {
        inline function v<T>():T
            return u.unserialize();

        autoPlay = v();
        autoRestore = v();
        directRender = v();
        showAlbumArt = v();
        showSnapshot = v();
        snapshotPath = Path.fromString(v());
    }

    /**
      * encode [this]
      */
    public inline function encode():String {
        return Serializer.run( this );
    }

    /**
      * decode a Preferences instance from [s]
      */
    public static inline function decode(s : String):Preferences {
        return Unserializer.run( s );
    }

    /**
      * write [this] Preferences data to a File
      */
    public function push():Void {
        var f = file();
        var data = encode();
        f.write( data );
    }

    /**
      * create and return a Preferences instance read from a File
      */
    public static function pull():Preferences {
        var f = file();
        if ( f.exists ) {
            return decode(f.read());
        }
        else {
            return new Preferences();
        }
    }

    /**
      * get the preferences File
      */
    private static inline function file():File {
        return new File(path());
    }

    /**
      * get the Path to the preferences file
      */
    private static inline function path():Path {
        return BPlayerMain.instance.appDir.preferencesPath();
    }

/* === Instance Fields === */

    public var autoPlay : Bool;
    public var autoRestore : Bool;
    public var directRender : Bool;
    public var showAlbumArt : Bool;

    public var snapshotPath : Path;
    public var showSnapshot : Bool;
}
