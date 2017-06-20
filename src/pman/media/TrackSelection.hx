package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry.FSEntryType;
import tannus.sys.FileSystem as Fs;
import tannus.http.Url;
import tannus.geom.Rectangle;

import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.media.MediaType;
import pman.ui.pl.TrackView;
import pman.media.info.Mark;
import pman.media.info.*;
import pman.async.*;
import pman.async.tasks.*;

import haxe.Serializer;
import haxe.Unserializer;

import electron.*;
import electron.Shell;
import electron.Tools.defer;
import Slambda.fn;
import tannus.math.TMath.*;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.ds.SortingTools;
using tannus.math.TMath;

using pman.async.VoidAsyncs;

class TrackSelection {
    /* Constructor Function */
    public function new(playlist:Playlist, tracks:Array<Track>):Void {
        this.playlist = playlist;
        this.tracks = tracks;
    }

/* === Instance Methods === */

    public inline function get(index : Int):Null<Track> {
        return tracks[index];
    }

    /**
      * deselect all [tracks]
      */
    public function deselect():Void {
        teach(function(track) {
            var tv = track.getView();
            if (tv != null) {
                tv.selected = false;
            }
        });
    }

    /**
      * pull [this] selection's tracks out of [playlist] and build a new playlist from them
      */
    public function extract():Playlist {
        remove();
        return new Playlist( tracks );
    }

    /**
      * remove [tracks] from [playlist]
      */
    public function remove():Void {
        each(function(l,t) l.remove( t ));
    }

    /**
      * get the indices of [this]
      */
    public function indices():Array<Int> {
        return map.fn([l,t]=>l.indexOf( t ));
    }

    /**
      *
      */
    public function invert():TrackSelection {
        return new TrackSelection(playlist, playlist.filter.fn(!tracks.has(_)));
    }

    /**
      * filter [this] Selection
      */
    public function filter(predicate : Playlist->Track->Bool):Array<Track> {
        return tracks.filter(function(track : Track):Bool {
            return predicate(playlist, track);
        });
    }

    /**
      * map [this] to Array<T> by [playlist] and each Track
      */
    public function map<T>(f : Playlist->Track->T):Array<T> {
        return tracks.map(f.bind(playlist, _));
    }

    /**
      * map to Array<T> only by Track
      */
    public function tmap<T>(f : Track->T):Array<T> {
        return map(function(l, t) return f( t ));
    }

    /**
      * invoke [action] on each Track
      */
    public function each(action : Playlist->Track->Void):Void {
        for (t in tracks) {
            action(playlist, t);
        }
    }
    public function teach(action : Track->Void):Void {
        each(function(l, t) action( t ));
    }

    /**
      * perform 'reduce' on [this] selection
      */
    public function reduce<T>(handler:T -> Track -> T, acc:T):T {
        for(track in tracks) {
            acc = handler(acc, track);
        }
        return acc;
    }

    /**
      * iterate over [this]'s tracks
      */
    public function iterator():Iterator<Track> {
        return tracks.iterator();
    }

    /**
      * build a context menu for [this] selection
      */
    public function buildMenu(done : MenuTemplate->Void):Void {
        var mt:MenuTemplate = new MenuTemplate();
        mt.push({
            label: 'Remove Selected From Queue',
            click: function(i,w,e) remove()
        });
        mt.push({
            label: 'Remove Not Selected From Queue',
            click: function(i,w,e) invert().remove()
        });
        mt.push({type: 'separator'});
        mt.push({
            label: 'Move Selected to New Tab',
            click: function(i,w,e) {
                player.session.setTab(player.session.newTab(function(tab) {
                    tab.playlist = extract();
                    tab.blurredTrack = tracks[0];
                    deselect();
                }));
            }
        });
        defer(function() {
            done( mt );
        });
    }

/* === Computed Instance Fields === */

    public var length(get, never):Int;
    private inline function get_length():Int return tracks.length;

/* === Instance Fields === */

    public var playlist : Playlist;
    public var tracks : Array<Track>;
}
