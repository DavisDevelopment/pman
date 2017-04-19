package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.*;
import pack.Tools.*;
import pack.ArgParser.Result as ArgDef;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class Packer extends Application {
    /* Constructor Function */
    public function new():Void {
        super();

        tasks = new Array();
    }

/* === Instance Methods === */

    /**
      * start pack
      */
    override function start():Void {
        exec(argv, function(?error:Dynamic) {
            if (error != null) {
                (untyped __js__('console.error'))(error);
            }
        });
    }

    /**
      * execute the task def given by the given arg list
      */
    private function exec(args:Array<String>, done:?Dynamic->Void):Void {
        var def = parseArgs( args );
        def.tasks.batch(function(?error : Dynamic) {
            done( error );
        });
    }

    /**
      * parse some arguments
      */
    private function parseArgs(args : Array<String>):ArgDef {
        return ArgParser.parse( args );
    }

    /**
      * display help text
      */
    private function help():Void {
        println('pman.pack\n - insert helpful info <here>\n');
    }

    /**
      * Queue a Task for execution
      */
    private inline function queue(task : Task):Void {
        tasks.push( task );
    }
    private inline function q(t:Task) queue( t );

    public var o(get, never):TaskOptions;
    private inline function get_o() return taskOptions;

/* === Instance Fields === */

    //public var taskNames : Array<String>;
    //public var availableDirectives : Array<Array<String>>;
    //public var availableFlags : Array<Array<String>>;

    public var taskOptions : TaskOptions;
    public var tasks : Array<Task>;

/* === Static Methods === */

    public static function main():Void {
        new Packer().start();
    }
}
