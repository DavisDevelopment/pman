package ;

import tannus.ds.Maybe;
import tannus.ds.Obj;

import tannus.node.Process;

import js.html.WorkerGlobalScope;
import js.html.DedicatedWorkerGlobalScope as Dws;

import pman.ww.WorkerPacket;
import pman.ww.WorkerPacket as Packet;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;


/**
  * class used to handle various long-running tasks from within a node subprocess
  */
class WorkerMain {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/**
	  * entry point for the app
	  */
	public function start():Void {
		listenForMessages( _onMessage );
	}

	/**
	  * process incoming packets
	  */
	private function onPacket(packet : Packet):Void {
	    switch ( packet.type ) {
            case 'command':
                trace( packet.data );
                send('command', [1, 2, 3, 4]);

            default:
                trace('Warning: Unhandled packet of type "${packet.type}"');
	    }
	}

	/**
	  * process incoming messages into packets
	  */
	private function _onMessage(raw : Dynamic):Void {
	    if (Packet.isPacket( raw )) {
	        var packet:Packet = cast raw;
	        packet = packet.decode();
	        onPacket( packet );
	    }
	}

	/**
	  * send a packet
	  */
	public function send(type:String, data:Dynamic, encoding:WorkerPacketEncoding=None):Void {
        _post(packet(type, data, encoding));
	}

    /**
      * create a Packet
      */
	private function packet(type:String, data:Dynamic, encoding:WorkerPacketEncoding):Packet {
	    var res:Packet = {
            type: type,
            data: data,
            encoding: None
	    };
	    res = res.encode( encoding );
	    return res;
	}

    /**
      * send [message] to [this] Process's parent
      */
	private function _post(message : Dynamic):Void {
	    if (isWebWorker()) {
	        self.postMessage( message );
	    }
        else {
            process.send( message );
        }
	}

	/**
	  * listen for messages
	  */
	private function listenForMessages(handler : Dynamic -> Void):Void {
	    if (isWebWorker()) {
	        self.onmessage = (function(event : Dynamic) {
	            handler( event.data );
	        });
	    }
        else {
            process.on('message', handler);
        }
	}

    /**
      * check whether [this] is a WebWorker
      */
	private function isWebWorker():Bool {
	    return (
	        (untyped __js__("typeof self !== 'undefined'")) &&
	        Std.is((untyped __js__('self')), Dws)
	    );
	}

/* === Computed Instance Fields === */

    public var self(get, never):Maybe<Dws>;
    private function get_self():Maybe<Dws> {
        if (isWebWorker()) {
            return cast (untyped __js__('self'));
        }
        else return null;
    }

    public var process(get, never):Null<Process>;
    private inline function get_process():Null<Process> {
        if (!isWebWorker()) {
            return untyped __js__('process');
        } else return null;
    }

    public var oself(get, never):Maybe<Obj>;
    private function get_oself():Maybe<Obj> {
        var s = self;
        return s.ternary(Obj.fromDynamic( s ), null);
    }

/* === Instance Fields === */

/* === Static Methods === */

	public static function main():Void {
		new WorkerMain().start();
	}
}
