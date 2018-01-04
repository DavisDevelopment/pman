package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.CompressJs;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class CompileWorkers extends BatchTask {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * execute [this]
      */
    override function execute(callback: VoidCb):Void {
        var scripts = Fs.readDirectory(path('scripts/')).filter.fn(_.endsWith('.worker.js')).map(fn(path('scripts/').plusString(_)));
        var compressors:Array<JsCompressor> = [JsCompressor.Uglify, JsCompressor.Closure];
        for (script in scripts) {
            addChild(new CompressJs(script, compressors));
        }
        callback();
    }

/* === Instance Fields === */
}
