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

class SaveSnapshot extends Task2<Path> {
    /* Constructor Function */
    public function new(p:Player, t:Track, time:Float):Void {
        super();

        this.player = p;
        this.track = t;
        this.trackPath = track.getFsPath();
        this.time = time;
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(done : Cb<Path>):Void {
        var sysname = systemName();
        trace( sysname );
        if (systemName() == 'Windows') {
            var toolPath = track.player.app.appDir.appPath('assets/ffmpeg-static');
            var ffmpegPath = toolPath.plusString('ffmpeg.exe');
            var ffprobePath = toolPath.plusString('ffprobe.exe');
            FFfmpeg.setFfmpegPath( ffmpegPath );
            FFfmpeg.setFfprobePath( ffprobePath );
        }
        take_snapshot( done );
    }

    /**
      * capture the snapshot itself
      */
    private function take_snapshot(done : Cb<Path>):Void {
        var thumbPath:Path = (App.getPath( ExtAppNamedPath.Pictures ).plusString('pman_snapshots'));
        var m = new FFfmpeg(trackPath);
        var fileNames = new Array();
        m.onError(function(error, stdout, stderr) {
            done( error );
        });
        m.onFileNames(function(list) {
            fileNames = list;
        });
        m.onEnd(function() {
            var snapPath:Path = thumbPath.plusString(fileNames[0]);
            done(null, snapPath);
        });
        m.screenshots({
            folder: thumbPath.toString(),
            filename: '%f@%s.png',
            size: '100%',
            timemarks: [time]
        });
    }

/* === Instance Fields === */

    private var player : Player;
    private var track : Track;
    private var trackPath : Path;
    private var time : Float;
}
