package pman.pmbash.args;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import pman.format.pmsh.Cmd;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;
import pman.pmbash.Interp;
import pman.pmbash.commands.Command;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using tannus.async.Asyncs;

class CmdArgParser {
    /* Constructor Function */
    public function new(cmd:Command, ?sub_commands:Array<String>, ?flag_aliases:Array<Array<String>>):Void {
        host = cmd;

        top = new TopLevel();

        commands = [];
        if (sub_commands != null)
            commands = sub_commands;

        aliases = [];
        if (flag_aliases != null)
            aliases = flag_aliases;

        dealias = dealias.memoize();
    }

/* === Instance Methods === */

    /**
      * parse the given args
      */
    public function parse(args : Array<CmdArg>):TopLevel {
        argv = new Stack( args );
        dir = null;
        top = new TopLevel();

        while ( !done ) {
            parseNext();
        }

        return top;
    }

    /**
      handle the next argument
     **/
    private function parseNext():Void {
        var tk = peek();

        switch tk.expr {
            case EWord(Ident(c)|String(c,_)):
                tk = pop();
                if (isFlag( c )) {
                    if (c.trim() == '--') {
                        commitDir();
                    }
                    else {
                        parseFlag( c );
                    }
                }
                else if (isCommand( c )) {
                    if (dir == null) {
                        initDir(dealias( c ));
                    }
                    else {
                        dir.addArg(CmdArg.fromString(dealias( c )));
                    }
                }
                else {
                    expr().addArg( tk );
                }

            case _:
                expr().addArg(pop());
        }
    }

    /**
      de-alias the given identifier
     **/
    dynamic function dealias(s: String):String {
        if (commands.has( s )) {
            return s;
        }

        for (set in aliases) {
            if (set.has( s )) {
                return set[0];
            }
        }

        return s;
    }

    /**
      parse out the given flag
     **/
    function parseFlag(flag: String):Void {
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
      check whether the given String seems to represent a command-line flag
     **/
    inline function isFlag(c : String):Bool {
        return c.startsWith('-');
    }

    /**
      check whether the given String seems to be a command identifier
     **/
    inline function isCommand(c: String):Bool return commands.has( c );

    inline function peek(?d : Int) return argv.peek( d );
    inline function pop() return argv.pop();
    inline function expr():DirectiveExpr return (dir != null ? dir : top);

    /**
      create and return a new DirectiveExpr
     **/
    inline function initDir(n: String):DirectiveExpr {
        commitDir();
        return dir = new DirectiveExpr( n );
    }

    /**
      do the stuff
     **/
    private function commitDir():Bool {
        if (dir != null) {
            top.addChild( dir );
            dir = null;
            return true;
        }
        else {
            return false;
        }
    }

/* === Computed Instance Fields === */

    public var done(get, never):Bool;
    private inline function get_done() return argv.empty;

/* === Instance Fields === */

    public var host: Command;
    public var argv : Stack<CmdArg>;
    public var top: TopLevel;
    public var dir: Null<DirectiveExpr> = null;

    public var aliases:Array<Array<String>>;
    public var commands: Array<String>;
}

/**
  an 'expression' of a command-line directive
 **/
class DirectiveExpr {
    public var name: String;
    public var flags: Dict<String, Dynamic>;
    public var args: Array<CmdArg>;
    public var children: Array<DirectiveExpr>;

    public function new(name: String) {
        this.name = name;
        this.flags = new Dict();
        this.args = new Array();
        this.children = new Array();
    }

    public function addArg(argument: CmdArg):Void {
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
