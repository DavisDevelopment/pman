package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.node.*;
import tannus.node.Fs;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class Concatenate extends Task {
    /* Constructor Function */
    public function new(dest:Path, ?srcs:Array<Path>):Void {
        super();

        this.dest = dest;
        sources = new Array();
        results = new Array();
        if (srcs != null) {
            for (src in srcs) {
                addSource( src );
            }
        }
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        var stack = new AsyncStack();
        for (src in sources) {
            stack.push(function( next ) {
                Fs.readFile(src.toString(), function(err, dat) {
                    if (err != null) {
                        callback( err );
                    }
                    else {
                        var data : ByteArray;
                        if (Std.is(dat, Buffer))
                            data = ByteArray.ofData(cast dat);
                        else if (Std.is(dat, String))
                            data = ByteArray.ofString(cast dat);
                        else {
                            callback('Error: invalid file read result:\n$dat');
                            return ;
                            data = ByteArray.alloc( 0 );
                        }
                        results.push( data );
                        next();
                    }
                });
            });
        }
        stack.run(function() {
            var b = new ByteArrayBuffer();
            for (bytes in results) {
                b.add( bytes );
            }
            var result:ByteArray = b.getByteArray();
            putResult(result, callback);
        });
    }

    /**
      * do something with the final result of the concatenation
      ---
      * default action is to write it to [dest]
      */
    private function putResult(data:ByteArray, callback:?Dynamic->Void):Void {
        FileSystem.write(dest, data);
        callback();
    }

    // add a Path to the source list
    public function addSource(path : Path):Void {
        sources.push( path );
    }

/* === Instance Fields === */

    public var dest : Path;
    public var sources : Array<Path>;
    public var results : Array<ByteArray>;
}
