package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
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

class GenerateBundleSnapshot extends GenerateThumbnail {
    public var time : Float;
    public function new(track:Track, size:String, time:Float):Void {
        super(track, size);
        this.time = time;
    }

    /**
      * execute [this] Task
      */
    override function execute(done : Cb<Path>):Void {
        Asyncs.series([_generate, copy], function(?error, ?paths) {
            done(error, (if (paths != null) paths[0] else null));
        });
    }

    /**
      * copy the file to the snapshot folder
      */
    private function copy(done : Cb<Path>):Void {
        done(null, path);
    }

    /**
      * generate the snapshot file
      */
    private function _generate(done : Cb<Path>):Void {
        super.execute( done );
    }

    /**
      * get the timestamp at which to generate the snapshot
      */
    override function getTimeMark():Float {
        return time;
    }

    /**
      * get the pattern used to generate the filename
      */
    override function getFilenamePattern():String {
        return 's%r@%s.png';
    }
}
