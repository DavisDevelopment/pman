package pman.async;

import pman.async.*;

using pman.async.Asyncs;

class ReadStream<T> {
    /* Constructor Function */
    public function new():Void {
        __onPacket = null;
    }

/* === Instance Methods === */

    /**
      * initiates the stream
      */
    public function open(callback : Cb<RSPacket<T>>):Void {
        __onPacket = callback;
        __start();
    }

    /**
      * reads all data packets from the stream
      */
    public function readAllDataPackets(done : Cb<Array<T>>):Void {
        var packets:Array<T> = new Array();
        open(function(?error, ?packet) {
            if (error != null)
                return done(error, null);

            switch ( packet ) {
                case RSPData( data ):
                    packets.push( data );

                case RSPClose:
                    done(null, packets);
            }
        });
    }

    /**
      * internal method that actually starts the streaming process
      */
    private function __start():Void {
        throw 'not implemented';
    }

    // 'send' a packet
    private function pkt(?packet:RSPacket<T>, ?error:Dynamic):Void {
        if (__onPacket != null) {
            __onPacket(error, packet);
        }
    }

    // send a 'close' signal
    private function __close():Void {
        pkt( RSPClose );
    }

    // send data
    private function __send(data : T):Void {
        pkt(RSPData( data ));
    }
    
    // raise an error
    private function __raise(error : Dynamic):Void {
        pkt(null, error);
    }

/* === Instance Fields === */

    private var __onPacket:Null<Cb<RSPacket<T>>>;
}

enum RSPacket<T> {
    RSPData(data : T);
    RSPClose;
}

class ReadStreamTransformer<TIn, TOut> extends ReadStream<TOut> {
    private var _src : ReadStream<TIn>;

    public function new(src : ReadStream<TIn>):Void {
        super();

        _src = src;
    }

    override function __start():Void {
        _src.open( __mapper );
    }

    private function __mapper(?error:Dynamic, ?packet:RSPacket<TIn>):Void {
        if (error != null) {
            __raise( error );
        }
        else if (packet != null) {
            switch ( packet ) {
                case RSPData( in_data ):
                    __send(__transform( in_data ));

                case RSPClose:
                    __close();
            }
        }
        else {
            throw 'Error: Neither an error nor a packet was provided';
        }
    }

    private function __transform(in_data : TIn):TOut {
        throw 'not implemented';
    }
}
