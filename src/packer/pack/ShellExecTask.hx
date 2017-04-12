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

class ShellExecTask extends Task {
    /* Constructor Function */
    public function new(cmd:String, ?o:Object):Void {
        super();

        command = cmd;
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
        ChildProcess.exec(command, options, function(error:Null<Dynamic>, stdout, stderr) {
            if (error != null) {
                done( error );
            }
            else {
                this.stdout = ByteArray.ofData( stdout );
                this.stderr = ByteArray.ofData( stderr );
                done();
            }
        });
    }

/* === Instance Fields === */

    public var command : String;
    public var options : Object;

    public var stdout : ByteArray;
    public var stderr : ByteArray;
}
