package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.node.*;
import tannus.node.WritableStream;
import tannus.node.ReadableStream;
import tannus.node.Duplex;
import tannus.node.Transform;
import tannus.async.*;

import edis.streams.*;

import pman.format.pmsh.Cmd;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using pman.format.pmsh.ExprTools;

class FuncCmd extends Cmd {
    /* Constructor Function */
    public function new(i:Interpreter, name:String, body:Expr):Void {
        super();

        this.interpreter = i;
        this.name = name;
        this.expr = body;
    }

    override function execute(i:Interpreter, argv:Array<CmdArg>, done:VoidCb):Void {
        var e:Expr = expr;
        trace(e.print());

        for (i in 0...argv.length) {
            switch argv[i].expr {
                case EWord(argWord):
                    e = e.replaceWord(Ref('${i + 1}'), argWord);

                case _:
                    e = e.replace(EWord(Ref('${i + 1}')), argv[i].expr);
            }
            trace(e.print());
            trace('' + e);
        }

        trace('' + e);
        
        i.execute(e, done);
    }

    public var expr(default, null): Expr;
    public var exprAsync(default, null): VoidAsync;
}
