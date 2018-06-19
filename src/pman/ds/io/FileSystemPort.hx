package pman.ds.io;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import edis.storage.fs.*;
import edis.storage.fs.async.FileSystem;

import pman.ds.Port;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class FileSystemPort<T> extends Port<T> {
    /* Constructor Function */
    public function new(fileSystem:FileSystem, location:Path):Void {
        super();

        fs = fileSystem;
        path = location;
    }

    public var fs: FileSystem;
    public var path: Path;
}
