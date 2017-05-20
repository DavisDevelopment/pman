package pman.ww;

import tannus.io.Signal;
import pman.ww.WorkerPacket;
import tannus.node.ChildProcess;
import js.html.Worker as NWorker;

import Slambda.fn;

class Boss {
    /* Constructor Function */
    public function new():Void {
        packetEvent = new Signal();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    public function init():Boss {
        _listen();
        return this;
    }

    public function send(type:String, data:Dynamic, encoding:WorkerPacketEncoding=None):Void {
        return ;
    }

    public function kill():Void {
        return ;
    }

    /**
      * listen for messages
      */
    private function _onMessage(handler : Dynamic -> Void):Void {
        return ;
    }

    /**
      * register a packet event handler
      */
    public inline function onPacket(handler:WorkerPacket->Void, once:Bool=false):Void {
        packetEvent.on(handler, once);
    }

    /**
      * register an event handler for the given type
      */
    public inline function on<T>(type:String, handler:Dynamic->Void):Void {
        packetEvent.when(fn(_.type == type), handler);
    }

    /**
      * start listening for packets
      */
    private function _listen():Void {
        _onMessage(function(o : Dynamic) {
            if (isPacket( o )) {
                //packetEvent.call(cast o);
                var pack:WorkerPacket = cast o;
                pack = pack.decode();
                packetEvent.call( pack );
            }
        });
    }

    /**
      * create a packet
      */
    private function packet(type:String, data:Dynamic, encoding:WorkerPacketEncoding):WorkerPacket {
        var res:WorkerPacket = {
            type: type,
            data: data,
            encoding: None
        };
        res = res.encode( encoding );
        return res;
    }

    /**
      * determine whether the given anonymous object is a packet
      */
    private function isPacket(o : Dynamic):Bool {
        return (
            (o.type != null && (o.type is String)) &&
            (o.encoding != null && WorkerPacketEncoding.isWorkerPacketEncoding( o.encoding ))
        );
    }

/* === Instance Fields === */

    public var packetEvent : Signal<WorkerPacket>;

/* === Static Methods === */

    // 'hire' a ChildProcess
    public static function hire_cp(name : String):Boss {
        var cp:ChildProcess;
        #if release
            cp = ChildProcess.fork('./resources/app/scripts/$name');
        #else
            cp = ChildProcess.fork( './scripts/$name' );
        #end
        return new NodeBoss( cp );
    }

    public static function hire_ww(name : String):Boss {
        var ww = new NWorker('../scripts/${name}.js');
        return new WebBoss( ww );
    }
}
