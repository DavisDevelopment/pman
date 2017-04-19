package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.node.*;
import tannus.node.Process;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Tools {
    /**
      *
      */
    public static inline function defer(action : Void->Void):Void {
        ((untyped __js__('process')).nextTick( action ));
    }

    /**
      * get the absolute Path to the pack script
      */
    public static function path(?s : String):Path {
        var result:Path = Path.fromString(untyped __js__('__dirname'));
        if (s != null) {
            result = result.plusString( s );
        }
        return result;
    }

    /**
      * perform a batch of Tasks
      */
    public static function batch<T:Task>(tasks:Array<T>, callback:?Dynamic->Void):Void {
        var stack = new AsyncStack();
        for (t in tasks) {
            stack.push(function(next) {
                t.run(function(?error : Dynamic) {
                    if (error != null) {
                        callback( error );
                    }
                    else {
                        next();
                    }
                });
            });
        }
        stack.run(function() {
            callback();
        });
    }

    /**
      * read entire data from Readable
      */
    public static function readAll(s:ReadableStream, cb:ByteArray->Void):Void {
        var buf = new ByteArrayBuffer();
        s.onData(function(dat : Dynamic) {
            if (Std.is(dat, Buffer)) {
                buf.add(ByteArray.ofData(cast dat));
            }
            else if (Std.is(dat, Binary)) {
                buf.add(cast dat);
            }
            else if (Std.is(dat, String)) {
                buf.addString(cast dat);
            }
            else {
                throw 'Error: invalid data $dat';
            }
        });
        s.onEnd(function() {
            cb(buf.getByteArray());
        });
    }

    /**
      * compare the last modified time
      */
    public static function compareLastModified(a:Path, b:Path):Int {
        return Reflect.compare(Fs.stat(a).mtime.getTime(), Fs.stat(b).mtime.getTime());
    }

    /**
      * check whether [a] is newer than [b]
      */
    public static function newerThan(a:Path, b:Path):Bool {
        return (compareLastModified(a, b) > 1);
    }

    /**
      * check whether any of the files referenced in [a] are newer than [b]
      */
    public static function anyNewerThan(a:Array<Path>, b:Path):Bool {
        return a.any.fn(newerThan(_, b));
    }
}
