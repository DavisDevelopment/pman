package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.PManError;
import pman.bg.media.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;

class MediaTools {
    //public static function toMedia
}

class MediaRowTools {
    /**
      * convert a MediaRow to a Media object
      */
    //public static inline function toMedia(row: MediaRow):Media {
        //return new Media(MediaSourceTools.toMediaSource( row.uri ), row);
    //}
}

class MediaSourceTools {
    public static function toUri(src: MediaSource):String {
        return (switch ( src ) {
            case MSLocalPath( path ): ('file://' + path.toString());
            case MSUrl( url ): url;
        });
    }

    public static inline function toMedia(src: MediaSource):Media {
        return new Media( src );
    }

/* === Variables === */
}

@:access( pman.bg.URITools )
class UriTools {
    /**
      * convert a URI String into a Media instance
      */
    public static function toMedia(uri: String):Null<Media> {
        uri = uri.toUri();
        if (uri != null) {
            var src = toMediaSource( uri );
            if (src != null) {
                return MediaSourceTools.toMedia( src );
            }
        }
        return null;
    }

    /**
      * convert the given URI to a MediaSource
      */
    public static function toMediaSource(uri: String):Null<MediaSource> {
        // trim off leading/trailing whitespace
        uri = uri.trim().urlDecode();

        // define inline function for creating MSLocalPath(...)
        inline function lp(s: String):MediaSource {
            return MSLocalPath(Path.fromString( s ).normalize());
        }

        // define inline function for handling Path's
        function handleFsPath(uri: String):Void {
            trace( uri );
            switch (URIUtils.os()) {
                // Damn Win32 path structure
                case 'Windows':
                    if (URIUtils.dos_path_pattern.match( uri )) {
                        throw lp( uri );
                    }

                // :P
                case osWithSaneFsPaths:
                    if (URIUtils.unix_path_pattern.match( uri )) {
                        throw lp( uri );
                    }
            }
        }

        try {
            handleFsPath( uri );

            if (uri.isUri()) {
                switch (uri.protocol()) {
                    case 'file':
                        var uri_path:String = uri.toFilePath().toString();
                        handleFsPath( uri_path );
                        throw PManError.PMEFileSystemError(EMalformedPathError(uri_path));
                        //throw 'Error: Malformed FileSystem path "${uri.toFilePath()}"';

                    default:
                        return MSUrl( uri );
                }
            }
            else {
                throw PManError.PMEMediaError(EMalformedURIError( uri ));
            }
        }
        catch (thrownReturn: MediaSource) {
            return thrownReturn;
        }

        throw PManError.PMEMediaError(EMalformedURIError( uri ));
    }



/* === Variables === */

    // pattern for Windows-paths
    //private static var winPath:RegEx = {~/^([A-Z]):\\/i;};
}

typedef PathUtils = pman.bg.PathTools;
typedef URIUtils = pman.bg.URITools;

