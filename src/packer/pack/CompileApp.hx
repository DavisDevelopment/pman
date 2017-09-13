package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

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

class CompileApp extends Task {
    /* Constructor Function */
    public function new(o : TaskOptions):Void {
        super();

        defines = o.app.haxeDefs;
    }

    override function execute(callback : ?Dynamic->Void):Void {
        var args:Array<String> = [];
        for (d in defines) {
            args.push('-D');
            args.push( d );
        }
        args.push('build.hxml');
        var cwd:Path = path().normalize().resolve( '../src' ).normalize();
        trace( cwd );
        shell = new ShellSpawnTask('haxe', args, {
            cwd: cwd.toString(),
            stdio: 'inherit'
        });
        shell.execute(function(?error : Dynamic) {
            callback( error );
        });
    }

    public var defines:Array<String>;
    public var shell:ShellSpawnTask;
}
