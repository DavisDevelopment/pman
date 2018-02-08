package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;
import pman.bg.MediaTools;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

class PathTools {
    /**
      * convert a Path to a URI
      */
    public static inline function toUri(path: Path):String {
        return ('file://' + path.toString());
    }

    /**
      * convert a Path to a MediaSource
      */
    public static inline function toMediaSource(path: Path):MediaSource {
        return UriTools.toMediaSource(toUri( path ));
    }
}
