package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

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
    public static function toMediaSource(uri: String):Null<MediaSource> {
        uri = uri.trim();
        if (uri.startsWith('/')) {
            return MSLocalPath(Path.fromString( uri ));
        }
        else if (uri.isUri()) {
            switch (uri.protocol()) {
                case 'file':
                    return MSLocalPath(uri.toFilePath());

                default:
                    return MSUrl( uri );
            }
        }
        else {
            return null;
        }
    }

    public static function toUri(src: MediaSource):String {
        return (switch ( src ) {
            case MSLocalPath( path ): 'file://$path';
            case MSUrl( url ): url;
        });
    }

    public static inline function toMedia(src: MediaSource):Media {
        return new Media( src );
    }
}

class UriTools {
    /**
      * convert a URI String into a Media instance
      */
    public static function toMedia(uri: String):Null<Media> {
        uri = uri.toUri();
        if (uri != null) {
            var src = MediaSourceTools.toMediaSource( uri );
            if (src != null) {
                return MediaSourceTools.toMedia( src );
            }
        }
        return null;
    }
}

typedef PathUtils = pman.bg.PathTools;
typedef URIUtils = pman.bg.URITools;
