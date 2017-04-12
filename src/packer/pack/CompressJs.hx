package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

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
    public function new(input:Path):Void {
        super();

        this.input = input;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        // get uncompressed source
        var code:String = FileSystem.read( input );
        // transform source code
        code = beforeParse( code );
        // parse source
        var ast = uglify.parse( code );
        // initialize ast
        ast.figure_out_scope();
        ast.compute_char_frequency();
        // mangle ast
        ast.mangle_names();
        // create compressor
        var compressor = uglify.Compressor({
            global_defs: {}
        });
        // apply compressor to ast
        ast.transform( compressor );
        // generate compressed output code from ast
        var minCode:String = ast.print_to_string();
        // transform compressed code
        minCode = afterCompress( minCode );
        // figure out where to put compressed code
        var output:Path = Path.fromString(input.toString());
        output.extension = 'min.js';
        // write compressed code to [output]
        FileSystem.write(output, minCode);
        // declare [this] Task complete
        callback();
    }

    /**
      * transform uncompressed source code
      */
    private function beforeParse(code : String):String {
        return code;
    }

    /**
      * transform compressed code
      */
    private function afterCompress(code : String):String {
        return code;
    }

/* === Instance Fields === */

    public var input:Path;
    
    private static var uglify:Dynamic = {require('uglify-js');};

    /**
      * create and return a batch task to compress all given js files
      */
    public static function compress(paths : Array<Path>):Task {
        return cast new BatchTask(cast paths.map.fn(new CompressJs(_)));
    }
}
