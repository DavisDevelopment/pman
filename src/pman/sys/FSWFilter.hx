package pman.sys;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.Globals.*;

//import pman.sys.ValueExtractor;
//import pman.sys.ValueExtractor as Ve;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;

enum FSWFilter {
    FilterFile(filter: FSWFileFilter);
    FilterDirectory(filter: FSWDirectoryFilter);
}

enum FSWFileFilter {
    PathMatch(pattern: RegEx);
}

enum FSWDirectoryFilter {
    PathMatch(pattern: RegEx);
}

@:native('FileProcessingInstruction')
enum Fpi {
    IReturn<Out>(extractor: Fde<Out>);
}

@:native('FileDataExtractor')
enum Fde <T> {
    EConst(v: T):Fde<T>;
    EGet(x:FileAttr<T>):Fde<T>;

    //EVal(v: Ve<T>):Fde<T>;
    EFunc<O>(f: T->O):Fde<O>;
}

enum FileAttr<T> {
    FAPath():FileAttr<Path>;
    FAStat():FileAttr<FileStat>;
    FAContent(?offset:Int, ?length:Int):FileAttr<ByteArray>;
}
