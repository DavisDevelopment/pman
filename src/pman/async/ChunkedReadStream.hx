package pman.async;

import pman.async.*;
import pman.async.ReadStream;

using pman.async.Asyncs;

class ChunkedReadStream<T> extends ReadStream<Array<T>> {
    public function readAllChunks(done : Cb<Array<T>>):Void {
        var packets:Array<T> = new Array();
        open(function(?error, ?packet) {
            if (error != null)
                return done(error, null);

            switch ( packet ) {
                case RSPData( chunk ):
                    packets = packets.concat( chunk );

                case RSPClose:
                    done(null, packets);
            }
        });
    }
}
