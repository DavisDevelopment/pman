package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.CompressJs;
import pack.Tools.*;

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

        // children.push(new RevisePackageJson( o ));
        if ( o.styles.compile ) {
            children.push(new CompileStyles( o ));
        }
        if (o.compress || o.scripts.compress) {
            var compressors:Array<JsCompressor> = [Uglify];
            if (o.hasFlag('-uglify') && !compressors.has(Uglify)) {
                compressors.push(Uglify);
            }
            if (o.hasFlag('-ccjs') && !compressors.has(Closure)) {
                compressors.push(Closure);
            }
            children.push(CompressJs.compress(
                [
                    path('scripts/content.js'),
                    path('scripts/background.js')
                ],
                compressors
            ));
        }
        if ( o.concat ) {
            children.push(new CatJsLibs( o ));
        }
    }
}
