package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.*;
import pack.Tools.*;

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
        taskNames = new Array();
        taskOptions = {
            release: false,
            compress: false,
            platforms: [],
            arches: [],
            styles: {
                compile: true,
                compress: false,
                concat: false
            },
            scripts: {
                compile: false,
                compress: false,
                concat: false
            },
            app: {
                compile: false,
                haxeDefs: []
            }
        };
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
      * parse command-line arguments
      */
    private function parseArgs():Void {
        var args = new Stack(argv.copy());
        
        while ( !args.empty ) {
            var s = args.pop();
            if (s.startsWith('-')) {
                switch ( s ) {
                    case '-compress':
                        o.compress = true;
                        o.app.haxeDefs.push( 'compress' );

                    case '-release':
                        o.release = true;
                        o.app.haxeDefs.push( 'release' );
                    
                    case '-concat':
                        o.styles.concat = true;
                        o.scripts.concat = true;

                    case '-D':
                        o.app.haxeDefs.push(args.pop());

                    case '-platform', '-p':
                        o.platforms.push(args.pop());

                    case '-arch', '-a':
                        o.arches.push(args.pop());

                    default:
                        null;
                }
            }
            else {
                taskNames.push( s );
            }
        }

        // if no platforms provided, all are used
        if (o.platforms.length == 0) {
            o.platforms = ['linux', 'win32'];
        }
        if (o.arches.length == 0) {
            o.arches = ['x64'];
        }

        parseTaskNames();
    }

    /**
      * parse task-names
      */
    private function parseTaskNames():Void {
        if (taskNames.length == 0) {
            queue(new Preprocess( o ));
        }
        else {
            for (n in taskNames) {
                switch ( n ) {
                    case 'preprocess', 'pp':
                        queue(new Preprocess( o ));

                    case 'recompile', 'compile', 'rc':
                        queue(new CompileApp( o ));

                    case 'pack', 'package':
                        queue(new BuildStandalones( o ));

                    case 'installers', 'bi':
                        queue(new BuildInstallers( o ));

                    default:
                        null;
                }
            }
        }
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

    public var taskNames : Array<String>;
    public var taskOptions : TaskOptions;
    public var tasks : Array<Task>;

/* === Static Methods === */

    public static function main():Void {
        new Packer().start();
    }
}

typedef TaskOptions = {
    release:Bool,
    compress:Bool,
    platforms:Array<String>,
    arches:Array<String>,
    styles: {
        compile: Bool,
        compress: Bool,
        concat: Bool
    },
    scripts: {
        compile: Bool,
        compress: Bool,
        concat: Bool
    },
    app: {
        compile: Bool,
        haxeDefs: Array<String>
    }
};
