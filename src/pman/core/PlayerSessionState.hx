package pman.core;

import haxe.extern.EitherType;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.math.Random;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.FileFilter;

import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.core.history.PlayerHistoryItem;
import pman.core.history.PlayerHistoryItem as PHItem;
import pman.core.PlayerPlaybackProperties;
import pman.core.JsonData;

import foundation.Tools.*;

import haxe.Serializer;
import haxe.Unserializer;

using Std;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.RandomTools;

class PlayerSessionState {
    /* Constructor Function */
    public function new():Void {
        playlist = new MediaSourceList();
        focused = -1;
    }

/* === Instance Methods === */

    /**
      * Pull info from a PlayerSession
      */
    public function pull(p : PlayerSession):Void {
        playlist = p.playlist.map.fn(_.source.toUri());
        focused = p.playlist.indexOf( p.focusedTrack );
    }

    /**
      * serialize [this]
      */
    @:keep
    public function hxSerialize(s : Serializer):Void {
        inline function w(x:Dynamic)
            s.serialize( x );

        var uris = playlist.toStrings();
        w( uris.length );
        for (uri in uris)
            w( uri );
        w( focused );
    }

    /**
      * unserialize [this]
      */
    @:keep
    public function hxUnserialize(u : Unserializer):Void {
        inline function v<T>():T
            return u.unserialize();

        var nuri:Int = v();
        var uris:Array<String> = new Array();
        for (i in 0...nuri) {
            uris.push(v());
        }
        playlist = uris;
        focused = v();
    }

    /**
      * encode [this]
      */
    public inline function encode():String return Serializer.run( this );
    public static inline function decode(s : String):PlayerSessionState return Unserializer.run( s );

/* === Instance Fields === */

    public var playlist : MediaSourceList;
    public var focused : Int;
}
