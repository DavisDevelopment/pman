package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.Tup2;
import tannus.async.*;
import tannus.math.*;
import tannus.sys.Path;
import tannus.TSys as Sys;

import pman.core.*;
import pman.media.*;
import pman.bg.media.*;
import pman.async.tasks.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;
import pman.pmbash.commands.FunctionalSubCommand;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

class HierCommand extends Command {
    /* Constructor Function */
    public function new():Void {
        super();

        subcommands = new Map();
        mainArgv = new Array();

        _build_();
    }

/* === Instance Methods === */

    function _build_() {
        //TODO
    }

    override function execute(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        _prep_(i, args);

        /**
          whether or not control over execution has been handed off to a subcommand
          [done] should NOT be invoked when [inControl] is false
         **/
        var inControl:Bool = !parseArguments(i, args, done);
        if ( inControl ) {
            main(i, mainArgv, done);
        }
    }

    public function addSubCommand(name:String, command:Command):HierCommand {
        for (n in _names_(name)) {
            subcommands[n] = command;
        }
        return this;
    }

    public function createSubCommand(name:String, ?options:FscOpts, ?init:FunctionalSubCommand->Void):FunctionalSubCommand {
        var sub: FunctionalSubCommand;
        addSubCommand(name, sub = createFsc(options, init));
        return sub;
    }

    public function subCmd(name:String, main:(i:Interpreter, self:FunctionalSubCommand, argv:Array<CmdArg>, done:VoidCb)->Void, ?init:FunctionalSubCommand->Void):FunctionalSubCommand {
        return createSubCommand(name, {main: main}, init);
    }

    function createFsc(?opts:FscOpts, ?create:FunctionalSubCommand->Void):FunctionalSubCommand {
        var subCmd = new FunctionalSubCommand( opts );
        if (create != null)
            create( subCmd );
        return subCmd;
    }

    /**
      [this] Command's "main" method
     **/
    function main(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        done();
    }

    function parseArguments(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Bool {
        if (args.length > 0) {
            var arg = args[0];
            var argv = argumentString( arg );
            if (subcommands.exists( argv )) {
                subcommands[argv].execute(i, args.slice(1), done);
                return true;
            }
            else {
                parseLocalArgToken(i, arg);
                return parseArguments(i, args.slice(1), done);
            }
        }
        else {
            return false;
        }
    }

    function parseLocalArgToken(i:Interpreter, arg:CmdArg) {
        if (isFlagArg( arg )) {
            return parseLocalFlagArg(i, arg);
        }
        else {
            return parseLocalArg(i, arg);
        }
    }

    function parseLocalArg(i:Interpreter, arg:CmdArg) {
        mainArgv.push( arg );
    }

    function parseLocalFlagArg(i:Interpreter, arg:CmdArg) {
        var text:String = argumentString( arg );
        while (text.startsWith('-'))
            text = text.after('-');
        if (text.empty()) return ;
        if (text.has('=')) {
            var def = splitDefine( text );
            _parseLocalDef(i, def._0, def._1);
        }
        else {
            _parseLocalFlag(i, text);
        }
    }

    function _parseLocalDef(i:Interpreter, name:String, value:String) {
        trace('def $name = "$value"');
    }

    function _parseLocalFlag(i:Interpreter, name: String) {
        trace('flag "$name"');
    }

    function _names_(name: String):Array<String> {
        var csre = ~/(?:\s*)?,(?:\s*)?/gm;
        return (csre.match(name) ? csre.split( name ) : [name]);
    }

    function isFlagArg(arg: CmdArg):Bool {
        return (argumentString(arg).startsWith('-'));
    }

    function splitDefine(arg: String):Tup2<String, String> {
        return arg.separate('=').with(new Tup2(_.before, _.after));
    }

    /**
      get the textual value of an argument
     **/
    function argumentString(arg: CmdArg):String {
        return switch arg {
            case {expr:EWord(Ident(text)|String(text, _)), value:_}: text;
            case {expr:expr, value:value} if (Std.is(value, String)): cast(value, String);
            case other: throw 'Not coercible to String: $other';
        };
    }

    function onlyArgs(f: Array<CmdArg>->VoidCb->Void):Interpreter->FunctionalSubCommand->Array<CmdArg>->VoidCb->Void {
        return ((a, b, c, d) -> f(c, d));
    }

/* === Instance Fields === */

    var subcommands:Map<String, Command>;
    var mainArgv:Array<CmdArg>;
}
