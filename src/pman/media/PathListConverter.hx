package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry;
import tannus.sys.FileSystem as Fs;

import pman.core.*;
import pman.ds.OpenableFileProbe;

import electron.ext.FileFilter;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/*
   class used to 'expand' an Array of Paths to files or directories to an Array of Paths to openable media files
*/
class PathListConverter {
    /* Constructor Function */
    public function new():Void {

    }

    /**
      * convert [this]
      */
    public function convert(paths : Array<Path>):Array<Path> {
        input = paths;
        output = new Array();

        for (p in input) {
            if (Fs.exists( p )) {
                if (Fs.isDirectory( p )) {
                    output = output.concat(probe( p ));
                }
                else {
                    output.push( p );
                }
            }
        }

        return output;
    }

    /**
      * get list of paths to openable files in the given Directory
      */
    private function probe(path : Path):Array<Path> {
        var filter = FileFilter.ALL;
        var dir = new Directory( path );
        var results = [];
        for (e in dir.entries) {
            switch ( e.type ) {
                case FSEntryType.File( file ):
                    results.push( file.path );

                case FSEntryType.Folder( sub ):
                    results = results.concat(probe( sub.path ));
            }
        }
        return results;
    }

/* === Instance Fields === */

    public var input : Array<Path>;
    public var output : Array<Path>;
}
