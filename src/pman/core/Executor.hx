package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;

import Slambda.fn;
import haxe.Constraints.Function;

#if !(eval || macro)
import pman.Globals.*;

import pman.core.exec.*;
import pman.core.exec.MicroTaskSpec;
#end

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.VoidAsyncs;
using pman.core.ExecutorTools;

class Executor {
    /* Constructor Function */
    public function new():Void {
        queue = new Stack();
        taskRunning = false;
        paused = false;
    }

/* === Instance Methods === */

    /**
      * pause [this] Executor
      */
    public inline function pause():Void {
        paused = true;
    }

    /**
      * resume [this] Executor
      */
    public function resume():Void {
        paused = false;
        _go();
    }

    /**
      * create and schedule a synchronous MicroTask
      */
    public function syncTask(func:Function, ?context:Dynamic, ?args:Array<Dynamic>, top:Bool=false):Void {
        _add(_syncTask(context, func, args), top);
    }

    /**
      * create and schedule an asynchronous MicroTask
      */
    public function asyncTask(func:Function, ?context:Dynamic, ?args:Array<Dynamic>, top:Bool=false):Void {
        _add(_asyncTask(context, func, args), top);
    }

    /**
      * create a new MicroTask
      */
    public function createMicroTask(async:Bool, context:Dynamic, func:Function, ?args:Array<Dynamic>):MicroTask {
        return new MicroTask(this, createSpec(async, context, func, args));
    }

    /**
      * create a MicroTaskSpec value
      */
    public inline function createSpec(async:Bool, context:Dynamic, func:Function, ?args:Array<Dynamic>):MicroTaskSpec {
        return ((async ? MTAsync : MTSync)(context, func, args));
    }

    /**
      * create and return a synchronous MicroTask
      */
    public function _syncTask(context:Dynamic, func:Function, ?args:Array<Dynamic>):MicroTask {
        return new MicroTask(this, MTSync(context, func, args));
    }

    /**
      * create and return an asynchronous MicroTask
      */
    public function _asyncTask(context:Dynamic, func:Function, ?args:Array<Dynamic>):MicroTask {
        return new MicroTask(this, MTAsync(context, func, args));
    }

    /**
      * add [task] onto the queue, and ensure that the execution stack is going
      */
    private function _add(task:MicroTask, top:Bool):Void {
        // queue the task
        (top ? queue.add : queue.under)( task );

        // maintain execution cycle
        _go();
    }

    /**
      * start/continue the execution cycle
      */
    private function _go():Void {
        if (!taskRunning && !queueEmpty && !paused) {
            _pop();
        }
    }

    /**
      * get the next MicroTask in the queue, and execute it
      */
    private function _pop():Void {
        var task = queue.pop();
        if (task != null) {
            _exec( task );
        }
    }

    /**
      * execute [task]
      */
    private function _exec(task : MicroTask):Void {
        var startTime = now();
        taskRunning = true;

        // start [task]'s execution
        task.execute(function(?error) {
            // delete [task]
            task.dispose();
            task = null;
            // disable [taskRunning] flag
            taskRunning = false;

            if (error != null) {
                report( error );
            }
            else {
                // calculate time taken for [task] to complete
                var execTime:Float = (now() - startTime);
                // if it took too long, defer the next task to the next call stack
                if (execTime > DEFERRENCE_THRESHOLD) {
                    defer( _go );
                }
                else {
                    _go();
                }
            }
        });
    }

/* === Computed Instance Fields === */

    public var queueEmpty(get, never):Bool;
    private inline function get_queueEmpty() return queue.empty;

    public var idle(get, never):Bool;
    private inline function get_idle() return (queueEmpty && !taskRunning);

/* === Instance Fields === */

    private var queue : Stack<MicroTask>;
    private var taskRunning : Bool;
    private var paused : Bool;

/* === Statics === */

    // longest a microtask can run before the next microtask is deferred to the next call stack
    private static inline var DEFERRENCE_THRESHOLD:Int = 850;
}
