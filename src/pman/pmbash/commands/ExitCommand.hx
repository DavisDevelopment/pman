package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.pmbash.commands.*;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class ExitCommand extends Command {
    override function execute(i:Interpreter, args:Array<Dynamic>, done:VoidCb):Void {
        defer(main.quit);
        done();
    }
}
