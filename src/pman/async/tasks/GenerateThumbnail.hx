package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.TSys.systemName;

import electron.Shell;
import electron.ext.App;
import electron.ext.ExtApp;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;

import ffmpeg.FFfmpeg;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class GenerateThumbnail extends Task2<Path> {
    /* Constructor Function */
    public function new(track:Track, size:String):Void {
        super();

        this.track = track;
        this.size = size;
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(done : Cb<Path>):Void {
        var b = track.getBundle();
        var m = new FFfmpeg(track.getFsPath());
        var fileNames:Array<String> = [];
        m.onError(function(error, stdout, stderr) {
            done(error, null);
        });
        m.onFileNames(function(names) {
            fileNames = names;
        });
        m.onEnd(function() {
            done(null, fileNames.map(b.subpath)[0]);
        });
        m.screenshots({
            folder: b.path.toString(),
            filename: 't%r.png',
            size: size,
            timemarks: [getTimeMark()]
        });
    }

    /**
      * get the timemark of the thumbnail
      */
    private function getTimeMark():Float {
        var r = new tannus.math.Random();
        if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
            var d = track.data;
            return r.randfloat(0.0, d.meta.duration);
        }
        else return 0.0;
    }

/* === Instance Fields === */

    public var track : Track;
    public var size : String;
}
