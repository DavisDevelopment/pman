package pman.tools;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

import pman.tools.ArgParser;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using pman.bg.URITools;

class DirectiveExecutor {
    /* Constructor Function */
    public function new(topLevel: DirectiveSpec):Void {
        this.root = topLevel;
        this.rd = root.toDirective();
    }

    /**
      * parse the root-level DirectiveExpr
      */
    public function exec(top: DirectiveExpr):Void {
        rd.ping(top.args, top.flags);
        for (e in top.children) {
            exec( e );
        }
    }

/* === Instance Fields === */

    private var root: DirectiveSpec;
    private var rd: Directive;
}
