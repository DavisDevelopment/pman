package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class Preprocess extends BatchTask {
    /* Constructor Function */
    public function new(o : TaskOptions):Void {
        super();

        children.push(new RevisePackageJson( o ));
        if ( o.styles.compile ) {
            children.push(CompileLess.compile([Path.fromString('styles/pman.less')]));
        }
        if (o.compress || o.scripts.compress) {
            children.push(CompressJs.compress([path('scripts/content.js'), path('scripts/background.js')]));
        }
    }
}
