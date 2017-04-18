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

class AppDirTransformer extends Task {
    /* Constructor Function */
    public function new():Void {
        super();

        this.path = Tools.path();
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        var _rej = reject;
        this.reject = (function(err : Dynamic) {
            callback( err );
        });

        var stack = new AsyncStack();
        stack.push( editMeta );
        stack.push( prune );
        stack.run(function() {
            this.reject = _rej;
            callback();
        });
    }

    /**
      * prune the directory hierarchy
      */
    private function prune(done : Void->Void):Void {
        defer( done );
    }

    /**
      * transform the given package.json Object
      */
    private function transformMeta(meta:Object, callback:Null<Dynamic>->Object->Void):Void {
        defer(function() {
            //trace(sub('package.json'));
            callback(null, meta);
        });
    }

    /**
      * alters the data contained in package.json
      */
    private function editMeta(done : Void->Void):Void {
        var meta = getMeta();
        transformMeta(meta, function(error:Null<Dynamic>, metaResult:Object) {
            //trace( metaResult );
            defer(function() {
                setMeta( metaResult );
                defer( done );
            });
        });
    }

    /**
      * get the metadata stored in package.json
      */
    private function getMeta():Object {
        var fileData = FileSystem.read(sub('package.json'));
        var data:Object = Json.parse( fileData );
        return data;
    }

    /**
      * set the metadata stored in package.json
      */
    private function setMeta(meta : Object):Void {
        var fileData = Json.stringify(meta, null, '   ');
        FileSystem.write(sub('package.json'), fileData);
    }

    /**
      * get a subpath of [path]
      */
    private inline function sub(s : String):Path return path.plusString(s);

    /**
      * report a fatal error in [this] Task
      */
    private dynamic function reject(error : Dynamic):Void {
        (untyped __js__('console.error'))( error );
        (untyped __js__('process.exit'))( 1 );
    }

/* === Instance Fields === */

    public var path : Path;
}
