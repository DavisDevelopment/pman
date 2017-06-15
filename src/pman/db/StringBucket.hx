package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import Slambda.fn;

using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;

@:expose('StringBucket')
class StringBucket<T> {
    public function new():Void {

    }

/* === Instance Methods === */

    public function readRaw():String return '';
    public function writeRaw(raw : String):Void return ;
    public function encode(v : T):String return throw 'not implemented';
    public function decode(s : String):T return throw 'not implemented';
    public function read():Array<T> _split(readRaw()).map(decode);
    public function write(a : Array<T>):Void writeRaw(_join(a.map(encode)));
    
    private function _split(raw : String):Array<String> {
        return raw.split( '\n' );
    }
    private function _join(list : Array<String>):String {
        return list.join( '\n' );
    }

/* === Instance Fields === */

}
