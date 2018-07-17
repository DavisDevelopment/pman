package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.geom2.Area;
import tannus.async.*;
import tannus.node.Buffer;
import tannus.node.Writable;
import tannus.node.Duplex;
import tannus.Nil;

import ffmpeg.Fluent;

import pman.async.Task1;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;

/**
  base-class for classes using fluent-ffmpeg heavily
 **/
class FluentTask extends Task1 {
    /* Constructor Function */
    public function new(src: String):Void {
        super();

        this.src = src;
        this.dests = [];
        fluent = Fluent.ffmpeg( src );

        _build_();
    }

/* === Instance Methods === */

    public function addOutput(out: Either<String, Either<Writable, Duplex>>):FluentTask {
        dests.push( out );
    }

    override function execute(done: VoidCb):Void {
        fluent.onError(function(error, out, err) {
            done( error );
        });

        fluent.onEnd(function() {
            afterExecution(fluent, function(?error) {
                done( error );
            });
        });

        beforeExecution(fluent, function(?error) {
            if (error != null)
                done( error );
            else {
                fluent.execute();
            }
        });
    }

    function beforeExecution(f:Fluent, next:VoidCb) {
        // bind event listeners
        _bind_( f );

        // add output destinations
        for (x in dests) {
            f.addOutput( x );
        }

        // continue
        next();
    }

    function afterExecution(f:Fluent, next:VoidCb) {
        next();
    }

    function _bind_(f: Fluent) {
        f.onProgress(function(event) {
            this.progress = event.percent;
        });

        f.onError(function(error, stdout, stderr) {
            report( error );
        });
    }

/* === Instance Fields === */

    public var src: String = null;
    public var dests: Array<Either<String, Either<Writable, Duplex>>>;
    public var fluent: Fluent = null;
}
