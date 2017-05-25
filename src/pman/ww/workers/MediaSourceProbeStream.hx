package pman.ww.workers;

import tannus.ds.*;
import tannus.io.*;

import pman.async.*;
import pman.async.ReadStream;
import pman.media.MediaSource;
import pman.ww.WorkerStream;
import pman.ww.workers.*;
import pman.ww.workers.HDDProbeInfo;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaSourceProbeStream extends HDDProbeStream<MediaSource> {
    /* Constructor Function */
    public function new(?type:BossType, ?info:HDDSProbeInfo):Void {
        super('diskprobe.worker', type, info);
    }

/* === Instance Fields === */


}
