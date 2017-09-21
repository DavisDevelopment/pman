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
import ffmpeg.Fluent;

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

class GenerateBundleSnapshots extends Task2<Array<Path>> {
    /* Constructor Function */
    public function new(track:Track, timemarks:Array<Float>, size:String='20%'):Void {
        super();

        this.track = track;
        this.timemarks = timemarks;
        this.size = size;
        this.paths = new Array();
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : Cb<Array<Path>>):Void {
        generate( done );
    }

    /**
      * generate the lists of thumbnails
      */
    @:access( pman.media.Track )
    private function generate(done : Cb<Array<Path>>):Void {
        // get the Bundle
        var bundle = track.getBundle();

        // create Fluent instance
        var m = Fluent.ffmpeg(track.getFsPath());

        // create variable to store generated filenames
        var fileNames:Array<String> = new Array();

        // handle errors
        m.onError(function(error, stdout, stderr) {
            done(error, null);
        });

        // when filenames have been generated
        m.onFileNames(function(list) {
            fileNames = list;
        });
        
        // when the ffmpeg command has completed
        m.onEnd(function() {
            paths = fileNames.map( bundle.subpath );
            done(null, paths);
        });

        m.renice( -10 );

        // start thumbnailing process
        m.screenshots({
            folder: bundle.path.toString(),
            filename: 's%r@%s.png',
            size: size,
            timemarks: untyped timemarks
        });
    }

/* === Instance Fields === */

    public var track : Track;
    public var timemarks : Array<Float>;
    public var size : String;
    public var paths : Array<Path>;
}
