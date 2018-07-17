package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.geom2.Area;
import tannus.math.Time;
import tannus.async.*;
import tannus.node.Buffer;
import tannus.Nil;

import ffmpeg.Fluent;

import pman.async.Task1;
import pman.bg.media.Dimensions;

import haxe.extern.EitherType as Either;

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

class MediaFileConvertTool extends FluentTask {
    public function clip(start:Float, end:Float):MediaFileConvertTool {
        op(MCClip(start, end));
        return this;
    }

    public function resize<T:Either<String, Area<Int>>>(size: T):MediaFileConvertTool {
        op(MCResize(cast size));
        return this;
    }

    public function transcode(format: String):MediaFileConvertTool {
        op(MCTranscode( format ));
        return this;
    }

    function op(e: ConvertOp) {
        ops.push( e );
    }

    override function beforeExecution(f:Fluent, next:VoidCb) {
        super.beforeExecution(f, function(?error) {
            if (error != null)
                next( error );
            else
                compileOps(f, next);
        });
    }

    function compileOps(f:Fluent, next:VoidCb):Void {
        for (op in ops) {
            switch op {
                case MCClip(start, end):
                    f.setStartTime( start );
                    f.setDuration(end - start);

                case other:
                    trace('Unsupported op $other');
                    throw 'Unexpected $other';
            }
        }

        next();
    }

    var ops: Array<ConvertOp> = {[];};
}

enum ConvertOp {
    MCClip(min:Float, max:Float);
    MCResize(size: Either<String, Area<Int>>);
    MCTranscode(format: String);
}
