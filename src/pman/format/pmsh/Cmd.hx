package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.async.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class Cmd {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    /**
      * execute [this] Cmd
      */
    public function execute(interp:Interpreter, args:Array<Dynamic>, done:VoidCb):Void {
        done();
    }

/* === Instance Fields === */

    public var name : String;
}
