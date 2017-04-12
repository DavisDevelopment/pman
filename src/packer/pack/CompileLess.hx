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

class CompileLess extends Task {
    /* Constructor Function */
    public function new(input:Path, ?output:Path):Void {
        super();

        this.input = input;
        if (output != null) {
            this.output = output;
        }
        else {
            this.output = Path.fromString(input.toString());
            this.output.extension = 'css';
        }
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        var lessCode:String = FileSystem.read( input );
        var options:Object = {
            filename: input.toString()
        };
        function lessComplete(error:Null<Dynamic>, result) {
            if (error != null)
                callback( error );
            else {
                var cssCode:String = result.css;
                FileSystem.write(output, cssCode);
                callback();
            }
        }
        less.render(lessCode, options, lessComplete);
    }

/* === Instance Fields === */

    public var input:Path;
    public var output:Path;


    private static var less:Dynamic = {require('less');};

    /**
      * create and return a Task that compiles all of the less files referenced by [paths]
      */
    public static function compile(paths : Array<Path>):Task {
        return cast new BatchTask(cast paths.map.fn(new CompileLess( _ )));
    }
}
