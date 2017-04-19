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
        parseArgs();
        tasks.batch(function(?error : Dynamic) {
            if (error != null) {
                (untyped __js__('console')).error( error );
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
      * parse task-names
      */
    private function parseDirectives():Void {
        if (o.directives.length == 0) {
            //queue(new Preprocess( o ));
            help();
        }
        else {

            for (dName in o.directives) {
                switch ( dName ) {
                    case 'preprocess':
                        queue(new Preprocess( o ));

                    case 'recompile':
                        queue(new CompileApp( o ));

                    case 'package':
                        o.compress = true;
                        o.concat = true;
                        o.app.haxeDefs.push( 'compress' );
                        var beforePack = o.directives.before( dName );
                        if (!(beforePack.has('recompile') && beforePack.has('preprocess'))) {
                            var batch = new BatchTask(cast untyped [
                                new CompileApp(o),
                                new Preprocess(o),
                                new BuildStandalones(o)
                            ]);
                            queue( batch );
                        }
                        else {
                            queue(new BuildStandalones( o ));
                        }

                    case 'installers':
                        queue(new BuildInstallers( o ));

                    default:
                        null;
                }
            }
        }
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
