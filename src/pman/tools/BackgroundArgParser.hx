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

class BackgroundArgParser {
    /* Constructor Function */
    public function new():Void {
        paths = new Array();
    }

/* === Instance Methods === */

    /**
      * parse the given args
      */
    public function parse(args : Array<String>):Void {
        argv = new Stack( args );
        paths = new Array();

        while ( !done ) {
            parseNext();
        }
    }

    /**
      * handle the next arg
      */
    private function parseNext():Void {
        var c = peek();
        if (isFlag( c )) {
            //TODO handle flags
            c = pop();
        }
        else if (isCommand( c )) {
            //TODO handle commands
            c = pop();
        }
        else {
            var cp = new Path(c = pop());
            if ( cp.absolute ) {
                paths.push( cp );
            }
            else {
                cp = Sys.getCwd().plusPath( cp );
                paths.push( cp );
            }
        }
    }

    private inline function isFlag(c : String):Bool {
        return c.startsWith('-');
    }

    private inline function isCommand(c : String):Bool {
        return false;
    }

    private inline function peek(?d : Int):String return argv.peek( d );
    private inline function pop():String return argv.pop();

/* === Computed Instance Fields === */

    public var done(get, never):Bool;
    private inline function get_done() return argv.empty;

/* === Instance Fields === */

    public var argv : Stack<String>;
    public var paths : Array<Path>;
}
