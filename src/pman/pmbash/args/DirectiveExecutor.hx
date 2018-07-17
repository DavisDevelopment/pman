package pman.pmbash.args;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import pman.format.pmsh.Cmd.CmdArg;
import pman.pmbash.args.CmdArgParser;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using tannus.async.Asyncs;

class DirectiveExecutor {
    /* Constructor Function */
    public function new(topLevel: DirectiveSpec):Void {
        this.root = topLevel;
        this.rd = root.toDirective();
    }

    /**
      * parse the root-level DirectiveExpr
      */
    public function exec(top:DirectiveExpr, cb:VoidCb):Void {
        rd.ping(top.args, top.flags, function(cmd, input) {
            cmd(input, cb);
        });
    }

/* === Instance Fields === */

    private var root: DirectiveSpec;
    private var rd: Directive;
}
