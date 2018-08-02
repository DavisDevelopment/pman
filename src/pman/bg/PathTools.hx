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

    public static inline function hasLeadingSlash(s:String):Bool {
        return (slashre.match(s.ltrim()) && slashre.matchedPos().pos == 0);
    }
    
    public static inline function hasTrailingSlash(s: String):Bool {
        return s.rtrim().endsWith( Path.separator );
    }

    public static inline function withoutTrailingSlash(s: String):String {
        return 
            if (s.trim().endsWith(Path.separator))
                 (s.beforeLast(Path.separator));
            else s;
    }

    public static inline function withoutLeadingSlash(s: String):String {
        return
            if (s.ltrim().startsWith(Path.separator))
                (s.after(Path.separator));
            else s;
    }

    static var slashre:RegEx = new RegEx(~/(?:\/|\\)+/gm);
    static var drivere:RegEx = new RegEx(~/^(?:([A-Za-z]{1,2}:))/gm);
    //static var slashre:RegEx = new RegEx(~//gm);
}
