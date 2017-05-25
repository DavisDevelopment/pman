package pman.ww;

import tannus.ds.*;
import tannus.io.*;

import pman.async.*;
import pman.async.ReadStream;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class WorkerStream<TIn, TOut> extends ReadStream<TOut> {
    /* Constructor Function */
    public function new():Void {
        super();

        bossType = WebWorker;
        name = '';
    }

/* === Instance Methods === */

    /**
      * open the stream
      */
    public function openStream():Void {
        open(function(?error:Dynamic, ?packet:RSPacket<TOut>) {
            if (error != null) {
                onError( error );
            }
            else if (packet != null) {
                switch ( packet ) {
                    case RSPData( data ):
                        onData( data );

                    case RSPClose:
                        onEnd();
                        boss.kill();
                }
            }
        });
    }

    /**
      * open [this] Worker stream
      */
    override function open(callback : Cb<RSPacket<TOut>>):Void {
        super.open( callback );
        boss.send('open', i, 'haxe');
        boss.on('packet', __packet);
        boss.on('error', __error);
    }

    /**
      * initialize the Boss object and its Worker
      */
    override function __start():Void {
        boss = (switch ( bossType ) {
            case WebWorker: Boss.hire_ww;
            case ChildProcess: Boss.hire_cp;
        })( name ).init();
    }

    /**
      * respond to incoming packets
      */
    private function __packet(packet : RSPacket<TOut>):Void {
        pkt(packet, null);
    }

    /**
      * handle errors
      */
    private function __error(error : Dynamic):Void {
        pkt(null, error);
    }

    /**
      * handle incoming data
      */
    public dynamic function onData(data : TOut):Void {
        return ;
    }

    /**
      * handle errors
      */
    public dynamic function onError(error : Dynamic):Void {
        throw error;
    }

    /**
      * handle closing of worker
      */
    public dynamic function onEnd():Void {
        trace('stream ended');
    }

/* === Instance Fields === */

    public var i : TIn;

    private var name : String;
    private var bossType : BossType;
    private var boss : Boss;
}

@:enum
abstract BossType (Int) from Int to Int {
    var WebWorker = 0;
    var ChildProcess = 1;
}
