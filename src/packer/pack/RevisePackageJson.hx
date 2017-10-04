package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.Json;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class RevisePackageJson extends Task {
    /* Constructor Function */
    public function new(o : TaskOptions):Void {
        super();

        this.o = o;
        packagePath = path( 'package.json' );
        data = Json.parse(FileSystem.read( packagePath ));
        newData = {};
    }

/* === Instance Methods === */

    /**
      * run [this] Task
      */
    override function execute(callback : VoidCb) {
        revise(function(?error : Dynamic) {
            if (error != null) {
                callback( error );
            }
            else {
                data.write( newData );
                var stringData = Json.stringify(data, null, '  ');
                FileSystem.write(packagePath, stringData);
                callback();
            }
        });
    }

    /**
      * alter newData
      */
    private function revise(callback : VoidCb):Void {
        newData['main'] = ((o.compress || o.release)?'scripts/background.min.js':'scripts/background.js');

        callback();
    }

    /**
      * prompt the user for info
      */
    private function prompt(done) {
        var stack = new AsyncStack();
        stack.push(function(next) {
            var version:String = data['version'];
            Prompts.string({
                text: 'app version ($version) ',
                defaultValue: version,
                validate: function(s) {
                    return (~/([0-9]+)\.([0-9]+)\.([0-9]+)/i).match( s );
                }
            }).then(function( version ) {
                newData['version'] = version;
                next();
            });
        });
        stack.run( done );
    }

/* === Instance Fields === */

    public var o : TaskOptions;
    public var packagePath : Path;
    public var data : Object;
    public var newData : Object;
}
