package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.ds.*;
import pman.async.*;
import pman.media.*;

import Slambda.fn;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda; 

class PathTools {
    /**
      * convert a list of File objects to a list of Tracks
      */
    public static function filesToPlaylist(files : Array<File>):Playlist {
        var expander = new FileListConverter();
        var playlist = expander.convert( files );
        return playlist;
    }

    /**
      * convert a list of Paths to a list of Tracks
      */
    public static function pathsToPlaylist(paths : Array<Path>):Playlist {
        var filePaths:Array<Path> = new Array();
        for (path in paths) {
            path = path.normalize();
            if (Fs.exists( path )) {
                if (Fs.isDirectory( path )) {
                    var dir:Directory = new Directory( path );
                    var dirFiles = dir.gather();
                    filePaths = filePaths.concat(dirFiles.map.fn( _.path ));
                }
                else if (Fs.isFile( path )) {
                    filePaths.push( path );
                }
            }
            else {
                continue;
            }
        }
        var files:Array<File> = filePaths.map.fn(new File( _ ));
        return filesToPlaylist( files );
    }
}
