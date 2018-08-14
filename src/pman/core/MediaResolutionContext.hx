package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.http.Url;
import tannus.http.QueryString;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;
import tannus.async.Feed;
import tannus.stream.Stream;

import electron.ext.FileFilter;

import pman.bg.media.MediaType;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaFeature;
import pman.media.Media;
import pman.media.MediaProvider;
import pman.media.MediaProviderDefinition;
import pman.media.Media as MediaItem;
import pman.media.MediaDriver;
import pman.display.media.MediaRenderer;

import Slambda.fn;
import tannus.math.TMath.*;
import pman.Errors;
import pman.Errors.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using pman.bg.URITools;
using pman.media.MediaTools;
using pman.async.Asyncs;
using tannus.FunctionTools;

/**
  class that handles the 'resolution' of MediaSource values into MediaProvider instances
 **/
class MediaResolutionContext {
    /* Constructor Function */
    public function new(player) {
        this.player = player;
        this.engine = player.app.engine;
    }

/* === Instance Methods === */

    /**
      resolve the given MediaSource to a MediaProvider
     **/
    public function resolve(src: MediaSource):Promise<MediaProvider> {
        // localize the MediaSource
        var localSrc = localize( src );

        // return the Promise
        return Promise.raise(new Error('BettyError', 0));
    }

    /**
      'localize' a MediaSource to another MediaSource
      this allows for all "incoming" location-references to be rewritten as needed and at the instance-level
     **/
    public function localize(src: MediaSource):MediaSource {
        return switch src {
            // defaults to a 'PassThrough' transformation
            case MSLocalPath(path): localizePathSource( path );
            case MSUrl(url): localizeUrlSource( url );
            case null: throw nullCheckFailed( src );
        }
    }

    /**
      transform / convert [path] to a MediaSource
     **/
    private function localizePathSource(path: Path):MediaSource {
        return MSLocalPath( path );
    }

    /**
      transform / convert [url] to a MediaSource
     **/
    private function localizeUrlSource(url: String):MediaSource {
        return MSUrl( url );
    }

    /**
      create and return a MIME-type from the given MediaSource
     **/
    public function sourceMimeType(src: MediaSource):Lazy<MediaType> {
        return switch src {
            case MSLocalPath(path):
                return mimeTypeFromPath( path );

            case MSUrl(url):
                return Lazy.ofConst(MTUnknown);
        }
    }

    /**
      create and return a MIME-type from a Path instance
     **/
    public function mimeTypeFromPath(path: Path):Lazy<MediaType> {
        var spath:String = path.normalize().toString();
        return Lazy.ofFunc(function() {
            return 
                if (FileFilter.VIDEO.test( spath ))
                    MediaType.MTVideo
                else if (FileFilter.AUDIO.test( spath ))
                    MediaType.MTAudio
                else if (FileFilter.IMAGE.test( spath ))
                    MediaType.MTImage
                else
                    MediaType.MTUnknown;
        });
    }

    /**
      convert from a 'local' MediaSource to a 'global' one
     **/
    public function globalize(src: MediaSource):MediaSource {
        return switch src {
            case MSLocalPath( path ): globalizePathSource( path );
            case MSUrl( url ): globalizeUrlSource( url );
        }
    }

    private function globalizePathSource(path: Path):MediaSource {
        return MSLocalPath( path );
    }

    private function globalizeUrlSource(url: String):MediaSource {
        return MSUrl( url );
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var player(default, null): Player;
    
    private var engine(default, null): Engine;
}
