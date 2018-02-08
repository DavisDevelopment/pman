package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.TSys as Sys;

import pman.bg.media.*;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

@:expose("UriTools")
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
        return (isUri( s ) ? s.before(':') : null);
    }

    /**
      * get the textual content of [s] after the protocol
      */
    public static function afterProtocol(s: String):Null<String> {
        var proto = protocol( s );
        if (proto == null) {
            return withoutLeadingSlashes( s );
        }
        else {
            var sub:String = '$proto:';
            s = s.replace(sub, '');
            s = withoutLeadingSlashes( s );
            return s;
        }
    }

    /**
      * checks that [s] appears to be a FileSystem path
      */
    public static inline function isPath(s: String):Bool {
        return path_pattern().match( s );
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
    public static inline function toFilePath(uri: String):Path {
        return Path.fromString(afterProtocol( uri ).urlDecode());
    }

    /**
      * percent-encode the given text
      */
    public static function percentEncode(text:String, ?leaveUnencoded:String):String {
        var pre:PRegEx = PRegEx.build(function(re: PRegEx) {
            return re.anyOf('!*\'();:@&=+$,/?#[]', false, true).or().whitespace();
        }).withOptions('g');
        trace(pre.toString());
        var re:RegEx = pre.toRegEx();
        return re.map(text, function(re) {
            return ('%' + re.matched(0).charCodeAt(0).hex(2));
        });
    }

    /**
      * obtain reference to the appropriate RegEx to use for the current platform
      */
    private static function path_pattern():RegEx {
        return (switch (os()) {
            case 'Windows': dos_path_pattern;
            default: unix_path_pattern;
        });
    }

    /**
      * get system name
      */
    private static function os():String {
        if (sys_name == null) {
            return (sys_name = Sys.systemName());
        }
        return sys_name;
    }

/* === Variables === */

    private static var uri_pattern:RegEx = {~/^([a-z0-9]+):/gi;};
    private static var unix_path_pattern:RegEx = {~/^(\.+\/)|^(\.\/)|^(\/)/g;};
    private static var dos_path_pattern:RegEx =  {~/^([A-Z]+:)?\\/g;};
    private static var sys_name:Null<String> = null;
}

typedef PathMixin = pman.bg.PathTools;
