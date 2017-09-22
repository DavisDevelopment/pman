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

class MicroTask {
    /* Constructor Function */
    public function new(e:Executor, spec:MicroTaskSpec):Void {
        executor = e;
        this.spec = spec;
    }

/* === Instance Methods === */

    /**
      * execute [this] MicroTask
      */
    public function execute(complete : VoidCb):Void {
        var invoke = specAsync();
        invoke( complete );
    }

    /**
      * create and return a function from [spec]
      */
    private function specAsync():VoidAsync {
        switch ( spec ) {
            // synchronous microtask without arguments
            case MTSync(context, func, null):
                return (function(done : VoidCb) {
                    try {
                        Reflect.callMethod(context, func, []);
                        done();
                    }
                    catch (error : Dynamic) {
                        done( error );
                    }
                });

            // synchronous microtask
            case MTSync(context, func, args):
                var call = bind(context, func, args);
                return (function(done:VoidCb) {
                    try {
                        call();
                        done();
                    }
                    catch (error : Dynamic) {
                        //js.Lib.rethrow();
                        done( error );
                    }
                });

            // asynchronous microtask without arguments
            case MTAsync(context, func, null):
                return (function(done : VoidCb) {
                    Reflect.callMethod(context, func, [done]);
                });

            // asynchronous microtask
            case MTAsync(context, func, args):
                var call = bind(context, func, args);
                return (function(done:VoidCb) {
                    call( done );
                });
        }
    }

    /**
      * create bound JSFunction
      */
    private function bind(context:Dynamic, func:Function, ?args:Array<Dynamic>):JSFunction {
        return us.bind.apply(us, bindParameters(context, func, args));
    }

    /**
      * get the parameter list to be passed to `_.bind`
      */
    private function bindParameters(context:Dynamic, func:Function, args:Maybe<Array<Dynamic>>):Array<Dynamic> {
        return args.ternary((untyped [func, context]).concat(_), untyped [func, context]);
    }

    /**
      * create a deep copy of [this] MicroTask
      */
    public function clone():MicroTask {
        return new MicroTask(executor, switch ( spec ) {
            case MTAsync(o, f, args): MTAsync(o, f, args);
            case MTSync(o, f, args): MTAsync(o, f, args);
        });
    }

    /**
      * delete properties of [this] Object from memory
      */
    public inline function dispose():Void {
        nad('executor');
        nad('spec');
    }

/* === Instance Fields === */

    public var spec : MicroTaskSpec;

    private var executor : Executor;
}
