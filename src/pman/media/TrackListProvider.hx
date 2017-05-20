package pman.media;

import pman.async.*;
import pman.async.ReadStream;

import pman.media.*;
import pman.media.MediaSource;

import electron.Tools.*;

using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using Slambda;

class TrackListProvider extends ChunkedReadStream<Track> {
    public static function fromMedia(m : MediaListProvider):TrackListProvider {
        return cast new MP2T( m );
    }
    public static function fromPlaylist(pl : Playlist):TrackListProvider {
        return cast new PlaylistProvider( pl );
    }
}

private class MP2T extends ReadStreamTransformer<Array<MediaProvider>, Array<Track>> {
    override function __transform(mpl : Array<MediaProvider>):Array<Track> {
        return mpl.map.fn(new Track( _ ));
    }
}

private class PlaylistProvider extends TrackListProvider {
    private var playlist:Playlist;

    public function new(pl : Playlist):Void {
        super();
        playlist = pl;
    }

    override function __start():Void {
        defer(function() {
            var steps:Array<VoidAsync> = [];
            inline function step(a : VoidAsync):Void {
                steps.push( a );
            }

            step(function(next) {
                defer(function() {
                    __send(playlist.toArray());
                    next();
                });
            });

            step(function(next) {
                defer(next.void());
            });

            steps.series(function(?error) {
                if (error != null)
                    __raise( error );
                else
                    __close();
            });
        });
    }
}
