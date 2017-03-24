package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.MediaType;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TrackListInitializer extends StandardTask<String, Int> {
    /* Constructor Function */
    public function new():Void {
        super();

        count = 0;
        tracks = new Array();
    }

/* === Instance Methods === */

    /**
      * initialize a group of Tracks all at once
      */
    public function initAll(tracks:Array<Track>, done:Int->Void):Void {
        this.count = 0;
        this.tracks = tracks;

        perform(function() {
            done( count );
        });
    }

    override function action(done : Void->Void):Void {
        var stack = new AsyncStack();
        for (t in tracks) {
            stack.push(init_track.bind(t, _));
        }
        stack.run( done );
    }

    /**
      * initialize a single Track
      */
    private function init_track(track:Track, done:Void->Void):Void {
        track.init(function() {
            count += 1;
            done();
        });
    }

/* === Computed Instance Fields === */

    public var count(get, set):Int;
    private inline function get_count():Int return result;
    private inline function set_count(v : Int):Int return (result = v);

/* === Instance Fields === */

    public var tracks : Array<Track>;
}
