package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.Path;
import tannus.sys.FileSystem in Fs;
import tannus.math.*;
import tannus.async.*;

import electron.ext.FileFilter;

import pman.Globals.*;
import edis.Globals.*;
import Slambda.fn;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class FileSystemSearchEngine extends SearchEngine<Path> {
    override function getValue(path: Path):String {
        return (path.toString());
    }

    override function getValues(path: Path):Array<String> {
        var vals = [];
        vals.push(getValue(path));
        for (x in path.pieces) {
            vals.push( x );
        }
        vals.push(path.name);
        return vals;
    }
}
