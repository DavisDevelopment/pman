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
import pman.pmbash.args.*;

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
using tannus.ds.MapTools;

class FunctionalSubCommand extends SubCommand {
    /* Constructor Function */
    public function new(?options: FscOpts) {
        super();

        if (options == null)
            options = {};
        specification = new FscDef(this, options);
    }

/* === Instance Methods === */

    override function main(i, argv, done:VoidCb) {
        trace('subcommand');
        specification.onSelf(i, this);
        specification.main(i, this, argv, done.wrap(function(_, ?error) {
            _reset();
            _( error );
        }));
    }

    public function setMain(f: (i:Interpreter, cmd:FunctionalSubCommand, argv:Array<CmdArg>, done:VoidCb)->Void):FunctionalSubCommand {
        specification.main = f.bind();
        return this;
    }

    public inline function onFlag(f: (i:Interpreter, cmd:FunctionalSubCommand, flag:String)->Void):FunctionalSubCommand {
        specification.onFlag = f;
        return this;
    }

    public inline function onDef(f: (i:Interpreter, cmd:FunctionalSubCommand, name:String, value:String)->Void):FunctionalSubCommand {
        specification.onDef = f;
        return this;
    }

    public inline function wrapMain(wrapper:(Interpreter->FunctionalSubCommand->Array<CmdArg>->VoidCb->Void)->Interpreter->FunctionalSubCommand->Array<CmdArg>->VoidCb->Void):FunctionalSubCommand {
        return setMain(specification.main.wrap(wrapper));
    }

    public inline function wrapOnFlag(wrapper:(Interpreter->FunctionalSubCommand->String->Void)->Interpreter->FunctionalSubCommand->String->Void):FunctionalSubCommand {
        return onFlag(specification.onFlag.wrap(wrapper));
    }

    public inline function wrapOnDef(wrapper:(Interpreter->FunctionalSubCommand->String->String->Void)->Interpreter->FunctionalSubCommand->String->String->Void):FunctionalSubCommand {
        return onDef(specification.onDef.wrap(wrapper));
    }

    public inline function onReset(f: Interpreter->FunctionalSubCommand->Void):FunctionalSubCommand {
        specification.reset = f;
        return this;
    }

    public inline function wrapOnReset(wrapper:(Interpreter->FunctionalSubCommand->Void)->Interpreter->FunctionalSubCommand->Void):FunctionalSubCommand {
        return onReset(specification.reset.wrap(wrapper));
    }

    /**
      must be called after assigning methods
     **/
    public function collectParameters():{flags:Set<String>, defs:Map<String, Dynamic>} {
        var o = {
            flags: new Set<String>(),
            defs: new Map()
        };

        wrapOnFlag(function(_, i, self, flag) {
            o.flags.push( flag );
            _(i, self, flag);
        });

        wrapOnDef(function(_, i, self, name, value) {
            o.defs[name] = value;
            _(i, self, name, value);
        });

        wrapOnReset(function(_, i, self) {
            o.flags = new Set();
            o.defs = new Map();
            _(i, self);
        });

        return o;
    }

    /**
      betty
     **/
    public function pythonicMain(f: Array<CmdArg>->Map<String, Dynamic>->VoidCb->Void):FunctionalSubCommand {
        var kwo = collectParameters();
        function kwargs():Map<String, Dynamic> {
            var kwm = new Map();
            for (x in kwo.flags)
                kwm[x] = true;
            for (k in kwo.defs.keys())
                kwm[k] = kwo.defs[k];
            return kwm;
        }

        setMain(onlyArgs(function(argv, done) {
            f(argv, kwargs(), done);
        }));

        return this;
    }

    function _reset() {
        specification.reset(interpreter, this);
    }

    override function _parseLocalFlag(i, flag:String) {
        specification.onFlag(i, this, flag);
    }

    override function _parseLocalDef(i, name, value) {
        specification.onDef(i, this, name, value);
    }

/* === Instance Fields === */

    public var specification: FscDef;
}

class FscDef {
    /* Constructor Function */
    public function new(cmd:FunctionalSubCommand, options:FscOpts):Void {
        this.options = options;
        this.command = cmd;

        if (options.main != null)
            this.main = options.main;
        if (options.onArg != null)
            this.onArg = options.onArg;
        if (options.onFlag != null)
            this.onFlag = options.onFlag;
        if (options.onDef != null)
            this.onDef = options.onDef;
        if (options.onSelf != null)
            this.onSelf = options.onSelf;
        if (options.reset != null)
            this.reset = options.reset;
    }

/* === Instance Methods === */

    public dynamic function main(i:Interpreter, self:FunctionalSubCommand, argv:Array<CmdArg>, done:VoidCb):Void {
        //TODO
    }

    public dynamic function onArg(i:Interpreter, self:FunctionalSubCommand, arg:CmdArg):Void {
        //TODO
    }

    public dynamic function onFlag(i:Interpreter, self:FunctionalSubCommand, flag:String):Void {
        //TODO
    }

    public dynamic function onDef(i:Interpreter, self:FunctionalSubCommand, name:String, value:String):Void {
        //TODO
    }

    public dynamic function onSelf(i:Interpreter, self:FunctionalSubCommand):Void {
        //TODO
    }

    public dynamic function reset(i:Interpreter, self:FunctionalSubCommand):Void {
        //TODO
    }

/* === Instance Methods === */

    public var options: FscOpts;
    public var command: FunctionalSubCommand;
}

typedef FscOpts = {
    ?main: (i:Interpreter, self:FunctionalSubCommand, argv:Array<CmdArg>, cb:VoidCb)->Void,
    ?onArg: (i:Interpreter, self:FunctionalSubCommand, arg:CmdArg)->Void,
    ?onFlag: (i:Interpreter, self:FunctionalSubCommand, flag:String)->Void,
    ?onDef: (i:Interpreter, self:FunctionalSubCommand, name:String, value:String)->Void,
    ?onSelf: (i:Interpreter, self:FunctionalSubCommand)->Void,
    ?reset: (i:Interpreter, self:FunctionalSubCommand)->Void
};
