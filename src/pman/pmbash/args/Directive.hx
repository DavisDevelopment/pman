package pman.pmbash.args;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import pman.format.pmsh.Cmd.CmdArg;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using tannus.async.Asyncs;

class Directive {
    /* Constructor Function */
    public function new(spec: DirectiveSpec) {
        this.spec = spec;
    }

/* === Instance Methods === */

    /**
      parse two given parameters into a DirectiveInput object
     **/
    public function parseInput(args:Array<CmdArg>, flags:Dict<String, String>):DirectiveInput {
        var res:DirectiveInput = {
            argv: args.copy(),
            flags: new Set(),
            kwargs: new Dict()
        };

        for (key in flags.keys()) {
            if (spec.flags.exists( key )) {
                switch (spec.flags[key]) {
                    case FVAny:
                        res.flags.push( key );

                    case FVCoerced(coerce):
                        res.kwargs.set(key, coerce(flags[key]));
                }
            }
        }

        return res;
    }

    /**
      * actually execute [this] directive
      */
    public function exec(i:DirectiveInput, cb:VoidCb):Void {
        var o = @:privateAccess spec.proto;
        mc(o._args, i.argv);
        mc(o._flags, i.flags);
        mc(o._kwargs, i.kwargs);

        if (o.main != null) {
            o.main(this, i.argv, i.flags, i.kwargs, cb);
        }
    }

    /**
      * hand basic command-line-input data over to [this] Directive to either hand off to a sub-directive or parse and execute
      */
    public function ping(argv:Array<CmdArg>, flags:Dict<String, Dynamic>, found:(exec:(i:DirectiveInput, cb:VoidCb)->Void, input:DirectiveInput)->Void):Void {
        var arg = argv[0];
        if (arg == null) {
            return found(exec, parseInput(argv, cast flags));
        }
        else {
            switch arg.expr {
                case EWord(Ident(name)), EWord(String(name, _)):
                    if (spec.subs.exists(name)) {
                        trace('sub found: $name');
                        var sub = spec.subs[name].toDirective();
                        return sub.ping(argv.slice(1), flags, found);
                    }
                    else {
                        return found(exec.bind(), parseInput(argv, cast flags));
                    }


                case other:
                    trace('Unexpected: $other');
                    return found(exec.bind(), parseInput(argv, cast flags));
            }

            return found(exec.bind(), parseInput(argv, cast flags));
        }
    }

    /**
      * call the given function, if it's not null
      */
    private static inline function mc<A>(f:haxe.Constraints.Function, x:A):Void {
        if (f != null) {
            f( x );
        }
    }

/* === Instance Fields === */

    private var spec: DirectiveSpec;
}

typedef DirectiveInput = {argv:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String, Dynamic>};
