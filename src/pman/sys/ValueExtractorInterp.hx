package pman.sys;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.storage.fs.async.EntryType;
import edis.storage.fs.async.EntryType.WrappedEntryType as Wet;
import edis.Globals.*;

import pman.sys.ValueExtractor;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

import Slambda.fn;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using tannus.ds.IteratorTools;
using pman.sys.ValueExtractorTools;

class ValueExtractorInterp {
    /* Constructor Function */
    public function new(?ctx: Dynamic) {
        scope = new Array();

        if (ctx != null) {
            setContext( ctx );
        }
    }

/* === Instance Methods === */

    public function setContext(ctx:Dynamic, root:Bool=false):Dynamic {
        if (context == ctx) {
            if ( root ) {
                scope = [];
            }
        }
        else {
            if ( root ) {
                scope = [];
            }
            else {
                ctPush( context );
                context = ctx;
            }
        }

        return context;
    }

    public function eval(value:ValueExtractor<Dynamic>, ?ctx:Dynamic, root:Bool=true):Promise<Dynamic> {
        this.value = value;
        if (ctx != null) {
            setContext()
        }
    }

    private function expr(v:Value)

    private function ctPush(v: Dynamic):Int {
        return scope.push({v: v});
    }

    private function ctPop(?lvl: Int):Dynamic {
        if (lvl != null) {
            scope = scope.slice(0, lvl);
            var e = scope[lvl - 1];
            return (e != null ? e.v : null);
        }
        else {
            var e = scope.pop();
            return (e != null ? e.v : null);
        }
    }

    private function ctHas(x: Dynamic):Bool {
        for (e in ali(scope)) {
            if (e.v == x) {
                return true;
            }
        }
        return false;
    }

    private static function ali<T>(a: Array<T>):Iterator<T> {
        return rii(a.length, 0).map(i -> a[i]);
    }

    private static function rii(max:Int, min:Int):Iterator<Int> {
        var n:Int = max;
        return ({
            next: (() -> n),
            hasNext: (() -> (--n >= min))
        });
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var value(default, null): ValueExtractor<Dynamic>;
    public var context(default, null): Dynamic;

    private var scope: Array<{v: Dynamic}>;
}
