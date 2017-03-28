package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.MediaType;
import pman.media.*;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TrackListDataLoader extends StandardTask<String, Array<TrackData>> {
    /* Constructor Function */
    public function new():Void {
        super();

        tracks = new Array();
        datas = new Map();
    }

/* === Instance Methods === */

    /**
      * load the stuff
      */
    public function load(tracks:Array<Track>, ?done:Array<TrackData>->Void):Void {
        this.tracks = tracks;
        this.datas = new Map();
        perform(function() {
            result = new Array();
            for (t in tracks) {
                result.push(datas[t.uri]);
            }
            if (done != null) {
                done( result );
            }
        });
    }

    override function action(done : Void->Void):Void {
        var stack = new AsyncStack();
        for (t in tracks) {
            stack.push(gdt.bind(t, _));
        }
        stack.run( done );
    }

    private function gdt(t:Track, next:Void->Void):Void {
        t.getData(function( data ) {
            datas[t.uri] = data;
            next();
        });
    }

/* === Instance Fields === */

    public var tracks : Array<Track>;
    public var datas : Map<String, TrackData>;
}
