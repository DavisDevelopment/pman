package pman.sid;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

#if electron
//import electron.ext.Clipboard as C;
import electron.Clipboard as C;
#end

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;

/*
   class for interacting with the system clipboard
*/
@:expose
class Clipboard {
    public static inline function readText(?type : String):Null<String> {
        return C.readText( type );
    }
    public static inline function writeText(text:String, ?type:String) {
        C.writeText(text, type);
    }
    public static inline function clear(?type : String):Void {
        C.clear( type );
    }
    public static inline function availableFormats(?type : String):Array<String> {
        return C.availableFormats( type );
    }
    public static inline function has(format:String, ?type:String):Bool {
        return C.has(format, type);
    }
    public static inline function read(format:String):String {
        return C.read( format );
    }
    public static function readBytes(format:String):Null<ByteArray> {
        var buf:Null<tannus.node.Buffer> = (untyped C).readBuffer(format);
        return if (buf != null) ByteArray.ofData( buf ) else null;
    }
    public static function write(data:{?text:String,?html:String}, ?type:String) {
        C.write(untyped data, type);
    }
}
