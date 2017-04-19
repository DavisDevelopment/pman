package pack;

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

class ArgParser {
    /* Constructor Function */
    public function new():Void {
        availableDirectives = [
            ['recompile', 'rc'],
            ['preprocess', 'pp'],
            ['package', 'pack', 'pk'],
            ['installers', 'installer', 'i']
        ];
        availableFlags = [
            ['--platform', '-p']
        ];

        taskOptions = {
            release: false,
            compress: false,
            concat: true,
            platforms: [],
            arches: [],
            directives: [],
            flags: new Dict(),
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
      * parse the given Array
      */
    public function parseArray(argv : Array<String>):TaskOptions {
        args = new Stack( argv );
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
                        o.setFlag(s, true);
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
                trace('Warning: "$d" is not a directive');
            }
        }

        return o;
    }

/* === Computed Instance Fields === */

    public var o(get, never):TaskOptions;
    private inline function get_o() return taskOptions;

/* === Instance Fields === */

    public var args : Stack<String>;
    public var availableDirectives : Array<Array<String>>;
    public var availableFlags : Array<Array<String>>;

    public var taskOptions : TaskOptions;

/* === Static Methods === */

    public static function parse(args : Array<String>):TaskOptions {
        return new ArgParser().parseArray( args );
    }
}
