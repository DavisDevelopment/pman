package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.core.*;
import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Interpreter;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class AliasCommand extends Command {
    private var code : String;
    private var partial : PmshPartial;
    private var _boundPartial : Null<Interpreter->Array<CmdArg>->VoidCb->Void>;

    public function new(?code:String, ?partial:PmshPartial):Void {
        super();

        this.code = code;
    }
    override function execute(i:Interpreter, args:Array<Dynamic>, done:VoidCb):Void {
        i.executeString(code, done);
    }
}
