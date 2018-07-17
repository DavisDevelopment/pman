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
using pman.format.pmsh.ExprTools;

/**
  wrapper-class that allows for shorthand aliases
 **/
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
    }

    /**
      * creates an expression based on partial expression and the provided parameters,
      * then executes that expression
      */
    override function execute(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        //var nargs = [];
        //for (e in partial.params) {
            //switch e {
                //case EWord(Ref(name)):
                    //if (name.isNumeric()) {
                        //var i = Std.parseInt(name);
                        //if (args[i] != null)
                            //nargs.push(args[i].expr);
                    //}
                    //else if (name == '@') {
                        //nargs = nargs.concat(args.map.fn(_.expr));
                    //}
                    //else {
                        //nargs.push( e );
                    //}

                //case _:
                    //nargs.push( e );
            //}
        //}
        
        i.execute(partial.toExpr(args.map.fn(_.expr)), done);
    }
}
