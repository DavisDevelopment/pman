package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.TSys as Sys;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class ClosureCompile extends Task {
    /* Constructor Function */
    public function new(input:Path, output:Path):Void {
        super();

        this.input = input;
        this.output = output;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : ?Dynamic->Void):Void {
        // the callback provided to closurecompiler
        function cccb(error:Null<Dynamic>, result:Null<Dynamic>):Void {
            if (error != null) {
                trace( error );
                //done( error );
            }
            if (Std.is(result, String)) {
                var str:String = cast result;
                FileSystem.write(output, str);
                done();
            }
        };

        (getMethod())([input.toString()], getOptions(), cccb.bind());
    }

    /**
      * build the options object
      */
    private function getOptions():Object {
        var o:Object = {
            compilation_level: 'SIMPLE',
            externs: []
        };
        return o;
    }

    /**
      * get the function used to do the stuff
      */
    private inline function getMethod():Dynamic {
        return cc.compile;
    }

/* === Instance Fields === */

    public var input : Path;
    public var output : Path;

/* === Static Fields === */

    private static var cc:Dynamic = {require('closurecompiler');};
}
