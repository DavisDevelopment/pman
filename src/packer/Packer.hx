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

        availableDirectives = [
            ['recompile', 'rc'],
            ['preprocess', 'pp'],
            ['package', 'pack', 'pk'],
            ['installers', 'installer', 'i']
        ];
        availableFlags = [
            ['--platform', '-p']
        ];

        tasks = new Array();
        taskOptions = {
            release: false,
            compress: false,
            concat: true,
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
            },
            directives: []
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
        var dirs = new Array();
        
        while ( !args.empty ) {
            var s = args.pop();
            if (s.startsWith('-')) {
                switch ( s ) {
                    case '-compress':
                        o.concat = true;
                        o.compress = true;
                        o.app.haxeDefs.push( 'compress' );

                    case '-release':
                        o.release = true;
                        o.app.haxeDefs.push( 'release' );
                    
                    case '-concat':
                        o.concat = true;
                        o.styles.concat = true;
                        o.scripts.concat = true;

                    case '-D':
                        o.app.haxeDefs.push(args.pop());

                    case '-platform', '-p':
                        var plat = args.pop();
                        switch ( plat ) {
                            case 'all':
                                o.platforms.push('linux');
                                o.platforms.push('win32');

                            default:
                                o.platforms.push( plat );
                        }

                    case '-arch', '-a':
                        var arch = args.pop();
                        switch ( arch ) {
                            case 'all':
                                o.arches = o.arches.concat(['ia32', 'x64', 'armv71']).unique();

                            default:
                                o.arches.push( arch );
                        }

                    default:
                        null;
                }
            }
            else {
                dirs.push( s );
            }
        }

        // if no platforms provided, all are used
        if (o.platforms.length == 0) {
            o.platforms = ['linux', 'win32'];
        }
        if (o.arches.length == 0) {
            o.arches = ['x64'];
        }

        // sanitize and simplify the list of 'task names'
        o.directives = [];
        for (d in dirs) {
            var valid:Bool = false;
            for (dspec in availableDirectives) {
                if (dspec.has( d )) {
                    o.directives.push(dspec[0]);
                    valid = true;
                    break;
                }
            }
            if ( !valid ) {
                println('Warning: "$d" is not a directive');
            }
        }

        parseDirectives();
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
    public var availableDirectives : Array<Array<String>>;
    public var availableFlags : Array<Array<String>>;

    public var taskOptions : TaskOptions;
    public var tasks : Array<Task>;

/* === Static Methods === */

    public static function main():Void {
        new Packer().start();
    }
}
