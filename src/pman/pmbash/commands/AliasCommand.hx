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
    //private var _boundPartial : Null<Interpreter->Array<CmdArg>->VoidCb->Void>;

    public function new(?code:String, ?partial:PmshPartial):Void {
        super();

        if (partial != null) {
            this.code = '';
            this.partial = partial;
        }
        else {
            this.code = code;
            this.partial = (new Interpreter().parsePartial( code ));
        }
        //_boundPartial = null;
    }

    /**
      * creates an expression based on partial expression and the provided parameters,
      * then executes that expression
      */
    override function execute(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        //if (_boundPartial == null) {
            //_boundPartial = partial.bind();
        //}
        //_boundPartial(i, args, done);
        i.execute(partial.toExpr(args.map.fn(_.expr)), done);
    }
}
