package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
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
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.PathTools;
using pman.media.MediaTools;

/**
  module of commands that adds a handful of bash's builtin commands
 **/
class Builtin extends HierCommand {
    override function _build_() {
        //cmd(this, 'echo', cmdEcho);
        cmd(this, 'cd', cmdCd);
        //cmd(this, 'ls', cmdLs);
    }

    function cmdCd(args:Array<CmdArg>, done:VoidCb) {
        try {
            if (args.empty()) {
                done();
            }
            else {
                cd(Path.fromString(argumentString(args[0])));
                done();
            }
        }
        catch (err: Dynamic) {
            done( err );
        }
    }

    function cd(p: Path) {
        if ( !p.absolute ) {
            p = get_cwd().plusPath( p ).normalize();
        }
        set_cwd( p );
    }

    @:access(pman.format.pmsh.Interpreter)
    function get_cwd():Path {
        if (!interpreter.environment.exists('PWD')) {
            interpreter.setenv('PWD', Sys.getCwd().toString());
        }
        return new Path(interpreter.getenv('PWD'));
    }
    function set_cwd(v: Path) {
        Sys.setCwd( v );
        interpreter.setenv('PWD', v.toString());
    }

    inline function cmd(self:HierCommand, name, f) self.subCmd(name, onlyArgs(f));
    inline function pcmd(self:HierCommand, name, f) {
        self.createSubCommand(name, {}, function(c) {
            c.pythonicMain( f );
        });
    }
}
