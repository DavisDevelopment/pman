package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import Slambda.fn;

import pman.Paths;
import pman.Paths.Library;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using pman.bg.MediaTools;

class Dirs {
    /**
      * get a path relative to the app's path
      */
    public static function appPath(?sub: String):Path {
        var res:Path = Paths.appPath();
        if (sub != null) {
            res = res.plusString( sub ).normalize();
        }
        return res;
    }

    /**
      * get a path relative to the userdata folder
      */
    public static function dataPath(?sub: String):Path {
        var res:Path = Paths.userData();
        if (sub != null) {
            res = res.plusString( sub ).normalize();
        }
        return res;
    }

    /**
      * get a path to a database file, or just the database folder
      */
    public static function dbPath(?sub: String):Path {
        return dataPath('pmdb/' + (sub != null ? sub : ''));
    }

    /**
      * get a Directory instance from [path]
      */
    public static inline function dir(path:Path, create:Bool=true):Null<Directory> {
        try {
            return new Directory(path, create);
        }
        catch (error: Dynamic) {
            return null;
        }
    }

    /**
      * get a set of Paths for a given library
      */
    public static function libraryPaths(library: Library):Array<Path> {
        if (libPaths.exists( library )) {
            return libPaths[library].copy();
        }
        else {
            var arr:Array<Path> = libPaths[library] = new Array();
            arr.push(Paths.library( library ));
            return arr;
        }
    }

    /**
      * get a list of Paths for Documents
      */
    public static function documentPaths():Array<Path> {
        return libraryPaths( Documents );
    }

    /**
      * get a list of Paths for Pictures
      */
    public static function picturePaths():Array<Path> {
        return libraryPaths( Pictures );
    }

    /**
      * get a list of Paths for Music
      */
    public static function musicPaths():Array<Path> {
        return libraryPaths( Music );
    }

    /**
      * get a list of Paths for Videos
      */
    public static function videoPaths():Array<Path> {
        return libraryPaths( Videos );
    }

    /**
      * get a list of Paths for Downloads
      */
    public static function downloadPaths():Array<Path> {
        return libraryPaths( Downloads );
    }

/* === Fields === */

    // Dict of Arrays of Paths for Libraries
    private static var libPaths:Dict<Library, Array<Path>> = {new Dict();};
}
