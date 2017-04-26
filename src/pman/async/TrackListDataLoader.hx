package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.math.Percent;

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
        this.tp = Percent.percent(1.0, tracks.length);
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

    /**
      * perform [this] Task
      */
    override function action(done : Void->Void):Void {
        var stack = new AsyncStack();
        for (t in tracks) {
            stack.push(gdt.bind(t, _));
        }
        stack.run( done );
    }

    /**
      * method used to get the data for a single Track
      */
    private function gdt(t:Track, next:Void->Void):Void {
        status = 'loading ${t.title}..';
        var loadr = new TrackDataLoader(t, BPlayerMain.instance.db.mediaStore);
        link(loadr, tp);
        var dp = loadr.load();
        dp.then(function( data ) {
            @:privateAccess t.data = data;
            var v = t.getView();
            if (v != null) {
                v.update();
            }
            status = 'loaded ${t.title}';
            next();
        });
    }

/* === Instance Fields === */

    private var tp : Percent;
    public var tracks : Array<Track>;
    public var datas : Map<String, TrackData>;
}
