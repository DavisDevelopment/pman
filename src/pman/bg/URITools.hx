package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.*;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

class URITools {
    /**
      * remove leading slashes from [s]
      */
    public static inline function withoutLeadingSlashes(s: String):String {
        while (s.startsWith('//')) {
            s = s.slice( 2 );
        }
        return s;
    }

    /**
      * checks that [s] appears to be a uri
      */
    public static inline function isUri(s: String):Bool {
        return (!s.empty() && uri_pattern.match( s ));
    }

    /**
      * attempt to extract the 'protocol' specified in the given uri
      */
    public static inline function protocol(s: String):Null<String> {
        return (isUri(s) ? s.before(':') : null);
    }

    public static function afterProtocol(s: String):Null<String> {
        var proto = protocol( s );
        if (proto == null) {
            return null;
        }
        else {
            return withoutLeadingSlashes(s.after( '$proto:' ));
        }
    }

    /**
      * checks that [s] appears to be a FileSystem path
      */
    public static inline function isPath(s: String):Bool {
        return (unix_path_pattern.match( s ) || dos_path_pattern.match( s ));
    }

    /**
      * convert (if possible) [s] into a valid URI
      */
    public static function toUri(s: String):Null<String> {
        if (!s.hasContent()) {
            return null;
        }
        else {
            s = withoutLeadingSlashes(s.trim()).nullEmpty();
            if (s == null) {
                return null;
            }
            else if (isUri( s )) {
                return canonicalizeUri( s );
            }
            else {
                try {
                    return toFilePath( s ).toString();
                }
                catch (error : Dynamic) {
                    return null;
                }
            }
        }
        return null;
    }

    /**
      * attempts to correct any formatting issues with the given URI
      */
    public static function canonicalizeUri(s: String):String {
        switch (protocol( s )) {
            case 'file', 'http', 'https':
                //TODO
        }
        return s;
    }

    /**
      * attempts to correct any formatting issues with the given Path string
      */
    public static function canonicalizePath(s: String):String {
        var path:Path = Path.fromString( s ).normalize();
        //TODO
        return path.toString();
    }

    /**
      * convert a URI to a file Path
      */
    public static function toFilePath(uri: String):Path {
        return Path.fromString(withoutLeadingSlashes(afterProtocol( uri )));
    }

    /**
      * convert [uri] to a MediaSource
      */
    //public static function toMedia(s: String):Null<Media> {
        //var uri:Null<String> = toUri( s );
        //if (uri != null) {
            //return new 
        //}
    //}

/* === Variables === */

    private static var uri_pattern:RegEx = {~/^([a-z0-9]+):/gi;};
    private static var unix_path_pattern:RegEx = {~/^(\.+\/)|(\.\/)|(\/)/g;};
    private static var dos_path_pattern:RegEx =  {~/^([A-Z]+:)?\\/g;};
}
