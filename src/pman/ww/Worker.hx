package pman.ww;

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
@:autoBuild(pman.ww.WorkerMacros.workerBuilder())
class Worker {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/**
	  * entry point for the app
	  */
	private function __start():Void {
		listenForMessages( _onMessage );
	}

	/**
	  * process incoming packets
	  */
	private function onPacket(packet : Packet):Void {
	    null;
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
	  * terminate [this] process
	  */
	private function exit(code : Int):Void {
	    if (isWebWorker()) {
	        self.close();
	    }
        else {
            process.exit( code );
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

	private inline function defer(f : Void->Void):Void {
	    (untyped __js__('process.nextTick')( f ));
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
}
