package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.node.*;
import tannus.node.WritableStream;
import tannus.node.ReadableStream;
import tannus.node.Duplex;
import tannus.node.Transform;

import edis.streams.*;
import haxe.io.*;

import pman.format.pmsh.NewParser;
import pman.format.pmsh.CmdIo;
import pman.format.pmsh.io.CmdInput;
import pman.format.pmsh.io.CmdOutput;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.html.JSTools.JSFunctionTools;
using tannus.FunctionTools;

@:structInit
class CmdArg {
    /* Constructor Function */
    public inline function new(e:Expr, v:Dynamic) {
        expr = e;
        value = v;
    }

    /* create a new CmdArg instance from some value */
    public static inline function fromString(s:String, literal:Bool=true):CmdArg {
        return new CmdArg(EWord(literal ? Ident(s) : String(s, 0)), s);
    }

/* === Instance Fields === */

    public var expr : Expr;
    public var value : Dynamic;
}

