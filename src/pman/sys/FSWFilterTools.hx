package pman.sys;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.storage.fs.async.EntryType;
import edis.storage.fs.async.EntryType.WrappedEntryType as Wet;
import edis.Globals.*;

import pman.sys.FSWFilter;
import pman.sys.ValueExtractor;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

import Slambda.fn;
import tannus.async.Promise._settle;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;

class FSWFilterTools {
    public static function evaluate(filter:FSWFilter, entry:Wet, ?cb:Cb<Bool>):BoolPromise {
        var fe:Pair<FSWFilter, Wet> = new Pair(filter, entry);
        switch ( fe ) {
            case {left:FilterDirectory(dir_filter), right:ETDirectory(dir)}:
                return FSWDirectoryFilterTools.evaluate(dir_filter, dir, cb);

            case {left:FilterFile(file_filter), right:ETFile(file)}:
                return FSWFileFilterTools.evaluate(file_filter, file, cb);

            case other:
                return promiseError(
                    new FileError(
                        TypeMismatchError,
                        '${fe.left} cannot be evaluated with ${fe.right} as the context'
                    )
                ).toAsync( cb ).bool();
        }
    }
}

class FSWFileFilterTools {
    public static function evaluate(filter:FSWFileFilter, file:File, ?cb:Cb<Bool>):BoolPromise {
        switch ( filter ) {
            case PathMatch(pattern):
                return promise(pattern.match(file.path.toString())).toAsync(cb).bool();
        }
    }
}

class FSWDirectoryFilterTools {
    public static function evaluate(filter:FSWDirectoryFilter, dir:Directory, ?cb:Cb<Bool>):BoolPromise {
        switch ( filter ) {
            case PathMatch(pattern):
                return promise(pattern.match(dir.path.toString())).toAsync(cb).bool();
        }
    }
}
