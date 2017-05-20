package pman.media;

import pman.async.*;
import pman.async.ReadStream;

import pman.media.*;
import pman.media.MediaSource;

using Slambda;
using pman.async.Asyncs;
using pman.media.MediaTools;

class MediaListProvider extends ChunkedReadStream<MediaProvider> {
    public static function fromSource(slp : MediaSourceListProvider):MediaListProvider {
        return cast new MS2MPCRS( slp );
    }
}

/*   ( MS )   (2)     ( MP )         ( CRS )
   MediaSource => MediaProvider ChunkedReadStream
*/
private class MS2MPCRS extends ReadStreamTransformer<Array<MediaSource>, Array<MediaProvider>> {
    override function __transform(msl : Array<MediaSource>):Array<MediaProvider> {
        return msl.map(MediaTools.mediaSourceToMediaProvider);
    }
}
