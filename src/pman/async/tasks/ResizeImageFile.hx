package pman.async.tasks;

import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.geom2.Area;
import tannus.TSys.systemName;
import tannus.node.Buffer;

import electron.Shell;
import electron.ext.App;
import electron.ext.ExtApp;

import pman.core.*;
import pman.media.*;
import pman.media.info.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;

import ffmpeg.Fluent;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class ResizeImageFile extends Task2<Path> {
    /* Constructor Function */
    public function new(s:Path, d:Path, size:Area<Int>):Void {
        super();

        ipath = s;
        opath = d;
        this.size = size;
    }

/* === Instance Methods === */

    /**
      * execute the Task
      */
    override function execute(done : Cb<Path>):Void {
        var fm = Fluent.ffmpeg( ipath );
        // if the ffmpeg process errors out
        fm.onError(function(err:Dynamic, stdout:Buffer, stderr:Buffer) {
            trace({
                out: stdout,
                err: stderr
            });
            done(err, null);
        });

        // when the process completes
        fm.onEnd(function() {
            // handle any post-fluent tasks.. then
            afterOperation(function(?error) {
                // report completion
                done(error, opath);
            });
        });

        fm.input( ipath );

        // perform the resizing operation
        _scale( fm );

        // perform any number of additional operations
        beforeOperation( fm );

        // allow for more operations to be performed extensibly
        fm.save( opath );
    }

    /**
      * after the operation has completed and the output file created
      */
    private function afterOperation(done : VoidCb):Void {
        defer(done.void());
    }

    /**
      * do things with (possibly modify?) the Fluent instance
      */
    private function beforeOperation(fm : Fluent):Void {
        trace( fm );
    }

    /**
      * private method for applying the 'scale' filter
      */
    private function _scale(m : Fluent):Void {
        //m.videoFilter('scale=${size.width}:${size.height}');
        m.videoFilter({
            filter: 'scale',
            options: {
                width: size.width,
                height: size.height
            }
        });
        trace({
            input: ipath.toString(),
            output: opath.toString(),
            video_filter: {
                filter: 'scale',
                options: {
                    width: size.width,
                    height: size.height
                }
            }
        });
    }

/* === Instance Fields === */

    private var ipath : Path;
    private var opath : Path;
    private var size : Area<Int>;
}
