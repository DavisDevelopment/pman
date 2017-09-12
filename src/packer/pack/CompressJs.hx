package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.TSys as Sys;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class CompressJs extends Task {
    /* Constructor Function */
    public function new(input:Path, ?compressors:Array<JsCompressor>):Void {
        super();

        this.input = input;
        this.output = input.toString();
        output.extension = 'min.js';
        this.tempOutput = (Sys.tempDir().plusString('temp.js'));
        if (compressors == null) {
            this.compressors = [Uglify, Closure];
        }
        else
            this.compressors = compressors;
    }

/* === Instance Methods === */

    /**
      * compress that shit
      */
    override function execute(callback : ?Dynamic->Void):Void {
        if (compressors.has(Closure)) {
            tempOutput = input.toString();
            tempOutput.extension = 'temp.js';
            var closure = new ClosureCompile(input, tempOutput);
            closure.run(function(?error : Dynamic) {
                if (error != null) {
                    return callback( error );
                }
                var ugly = new UglifyJs(tempOutput, output);
                ugly.run(function(?error : Dynamic) {
                    FileSystem.deleteFile( tempOutput );
                    callback( error );
                });
            });
        }
        else {
            var ugly = new UglifyJs( input );
            ugly.run( callback );
        }
    }

    /**
      * get a compressor Task
      */
    private function getTask(c : JsCompressor):Task {
        switch ( c ) {
            case Uglify:
                return new UglifyJs( input );

            case Closure:
                return new ClosureCompile(input, tempOutput);
        }
    }

/* === Instance Fields === */

    public var input : Path;
    public var output : Path;
    public var tempOutput : Path;
    public var compressors : Array<JsCompressor>;

/* === Static Methods === */

    public static function compress(paths:Array<Path>, ?compressors:Array<JsCompressor>):Task {
        return cast new BatchTask(cast paths.map.fn(new CompressJs(_, compressors)));
    }
}

@:enum
abstract JsCompressor (String) from String to String {
    inline var Uglify = 'uglify';
    inline var Closure = 'closure';
}
