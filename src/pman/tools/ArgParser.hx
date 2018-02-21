package pman.tools;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using pman.bg.URITools;

class ArgParser {
    /* Constructor Function */
    public function new():Void {
        top = new TopLevel();

        commands = [
            // content-control
            'open', 'close', 'close-all',

            // media control
            'play', 'pause', 'stop',

            // editing
            'slice', 'convert', 'extract-audio',

            // data manipulation
            'set', 'remove', 'search',

            // database
            'update', 'clean', 'patch',

            // library
            'scan'
        ];
        aliases = [
            ['--background-only', '--daemon', '-bgo'],
            ['-dimensions', '-dim']
        ];

        dealias = dealias.memoize();
    }

/* === Instance Methods === */

    /**
      * parse the given args
      */
    public function parse(args : Array<String>):TopLevel {
        argv = new Stack( args );
        dir = null;
        top = new TopLevel();

        while ( !done ) {
            parseNext();
        }

        return top;
    }

    /**
      * handle the next arg
      */
    private function parseNext():Void {
        var c = peek();
        if (isFlag( c )) {
            c = pop();
            if (c.trim() == '--') {
                commitDir();
            }
            else {
                parseFlag( c );
            }
        }
        else if (isCommand( c )) {
            c = pop();

            if (dir == null) {
                initDir(dealias( c ));
            }
            else {
                //TODO maybe parse out child-commands
                dir.addArg(dealias( c ));
            }
        }
        else {
            expr().addArg(pop());
        }
    }

    private dynamic function dealias(s: String):String {
        for (set in aliases) {
            if (set.has( s )) {
                return set[0];
            }
        }
        return s;
    }

    private function parseFlag(flag: String):Void {
        flag = dealias( flag );
        while (flag.startsWith('-'))
            flag = flag.after('-');
        if (flag.has( '=' )) {
            var value = flag.after('=');
            flag = flag.before('=');
            expr().addFlag(flag, value);
        }
        
        expr().addFlag( flag );
    }

    /**
      * check if the given String seems to represent a command-line flag
      */
    private inline function isFlag(c : String):Bool {
        return c.startsWith('-');
    }

    private inline function isCommand(c: String):Bool return commands.has( c );

    private inline function peek(?d : Int):String return argv.peek( d );
    private inline function pop():String return argv.pop();
    private inline function expr():DirectiveExpr return (dir != null ? dir : top);

    private function initDir(n: String):DirectiveExpr {
        commitDir();
        return dir = new DirectiveExpr( n );
    }

    private function commitDir():Bool {
        if (dir != null) {
            top.addChild( dir );
            dir = null;
            return true;
        }
        else return false;
    }

/* === Computed Instance Fields === */

    public var done(get, never):Bool;
    private inline function get_done() return argv.empty;

/* === Instance Fields === */

    public var argv : Stack<String>;
    public var top: TopLevel;
    public var dir: Null<DirectiveExpr> = null;

    public var aliases:Array<Array<String>>;
    public var commands: Array<String>;
}

class DirectiveExpr {
    public var name: String;
    public var flags: Dict<String, Dynamic>;
    public var args: Array<String>;
    public var children: Array<DirectiveExpr>;

    public function new(name: String) {
        this.name = name;
        this.flags = new Dict();
        this.args = new Array();
        this.children = new Array();
    }

    public function addArg(argument: String):Void {
        args.push( argument );
    }

    public function addFlag(name:String, ?value:Dynamic):Void {
        if (value == null)
            value = true;
        flags.set(name, value);
    }

    public function addChild(child: DirectiveExpr):Void {
        children.push( child );
    }
}

class TopLevel extends DirectiveExpr {
    public function new() {
        super('[toplevel]');
    }
}
