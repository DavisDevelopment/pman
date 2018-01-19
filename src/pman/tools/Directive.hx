package pman.tools;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

import pman.tools.DirectiveSpec;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using pman.bg.URITools;
using pman.bg.DictTools;

class Directive {
    /* Constructor Function */
    public function new(spec: DirectiveSpec) {
        this.spec = spec;
    }

/* === Instance Methods === */

    /**
      * parse two given parameters into a DirectiveInput object
      */
    public function parseInput(args:Array<String>, flags:Dict<String, String>):DirectiveInput {
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
    public function exec(i: DirectiveInput):Void {
        var o = @:privateAccess spec.proto;
        mc(o._args, i.argv);
        mc(o._flags, i.flags);
        mc(o._kwargs, i.kwargs);

        if (o.main != null) {
            o.main(this, i.argv, i.flags, i.kwargs);
        }
    }

    /**
      * hand basic command-line-input data over to [this] Directive to either hand off to a sub-directive or parse and execute
      */
    public function ping(argv:Array<String>, flags:Dict<String, Dynamic>):Void {
        var arg:String = argv[0];
        if (arg.hasContent()) {
            if (spec.subs.exists( arg )) {
                var sub = spec.subs[arg].toDirective();
                sub.ping(argv.slice(1), flags);
            }
            else {
                exec(parseInput(argv, cast flags));
            }
        }
        else {
            exec(parseInput(argv, cast flags));
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

typedef DirectiveInput = {argv:Array<String>, flags:Set<String>, kwargs:Dict<String, Dynamic>};
