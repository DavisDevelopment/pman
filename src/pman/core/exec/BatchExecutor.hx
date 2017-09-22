package pman.core.exec;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;

import pman.core.Executor;
import pman.core.exec.MicroTaskSpec;

import Slambda.fn;
import haxe.Constraints.Function;

#if !(eval || macro)
import pman.Globals.*;
import tannus.html.JSFunction;
#end

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using tannus.async.VoidAsyncs;

class BatchExecutor extends Executor {
    /* Constructor Function */
    public function new(parent : Executor):Void {
        super();

        pause();

        this.parent = parent;
        _complete = new VoidSignal();
        _last_step_method = null;
    }

/* === Instance Methods === */

    public function start(?complete : Void->Void):Void {
        if (complete != null)
            onComplete( complete );
        resume();
    }

    public function onComplete(done : Void->Void):Void {
        _complete.once( done );
    }

    override function _next(execTime:Float, task:MicroTask):Void {
        if ( queueEmpty ) {
            defer(_complete.fire);
        }
        else {
            super._next(execTime, task);
        }
    }

/* === Instance Fields === */

    public var parent : Executor;

    private var _complete : VoidSignal;
    private var _last_step_method : Null<String>;
}
