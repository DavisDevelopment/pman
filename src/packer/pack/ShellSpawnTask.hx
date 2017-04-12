package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.node.ChildProcess;
import tannus.TSys as Sys;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class ShellSpawnTask extends Task {
    /* Constructor Function */
    public function new(cmd:String, args:Array<String>, ?o:Object):Void {
        super();

        command = cmd;
        this.args = args;
        options = {};
        if (o != null) {
            options.write( o );
        }
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : ?Dynamic->Void):Void {
        exec( done );
    }

    /**
      * run the shell command and get the result
      */
    private function exec(done : ?Dynamic->Void):Void {
        process = ChildProcess.spawn(command, args, options);
        process.on('close', function(code : Int) {
            done();
        });
    }

/* === Instance Fields === */

    public var command : String;
    public var args : Array<String>;
    public var options : Object;

    public var process : ChildProcess;
}
