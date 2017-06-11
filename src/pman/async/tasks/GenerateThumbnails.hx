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

class GenerateThumbnails extends Task2<Array<Path>> {
    /* Constructor Function */
    public function new(track:Track, count:Int=12, size='20%'):Void {
        super();

        this.track = track;
        this.count = count;
        this.size = size;
        this.paths = new Array();
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : Cb<Array<Path>>):Void {
        if (systemName() == 'Windows') {
            var toolPath:Path = track.player.app.appDir.appPath('assets/ffmpeg-static');
            var ffmpegPath:Path = toolPath.plusString('ffmpeg.exe');
            var ffprobePath:Path = toolPath.plusString('ffprobe.exe');
            FFfmpeg.setFfmpegPath( ffmpegPath );
            FFfmpeg.setFfprobePath( ffprobePath );
        }

        generate( done );
    }

    /**
      * generate the lists of thumbnails
      */
    @:access( pman.media.Track )
    private function generate(done : Cb<Array<Path>>):Void {
        var bundle = track.getBundle();
        var m = new FFfmpeg(track.getFsPath());
        var fileNames:Array<String> = new Array();
        m.onError(function(error, stdout, stderr) {
            done(error, null);
        });
        m.onFileNames(function(list) {
            fileNames = list;
            trace('got filenames');
            trace( fileNames );
        });
        m.onEnd(function() {
            //paths = fileNames.map.fn(bundle.path.plusString( _ ));
            paths = fileNames.map( bundle.subpath );
            //reduce_precision( done );
            done(null, paths);
        });
        m.renice( -10 );
        m.screenshots({
            folder: bundle.path.toString(),
            filename: 't[%i:${count}]%r@%s.png',
            size: size,
            //count: count
            timemarks: untyped bundle.getTimemarks( count )
        });
    }

    /**
      * reduce the precision of the time offset
      */
    private function reduce_precision(done : Cb<Array<Path>>):Void {
        for (p in paths) {
            var name = p.name, ba = name.before('@'), ts = name.after('@').before('.png');
            ts = Std.parseFloat( ts ).toFixed( 1 );
            name = (ba + '@' + ts + '.png');
            FileSystem.rename(p, name);
            p.name = name;
        }
        defer(function() {
            done(null, paths);
        });
    }

/* === Instance Fields === */

    public var track : Track;
    public var count : Int;
    public var size : String;
    public var paths : Array<Path>;
}
