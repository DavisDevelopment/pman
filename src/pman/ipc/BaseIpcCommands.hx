package pman.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import edis.concurrency.*;
import edis.concurrency.WorkerPacket;

import haxe.extern.EitherType;
import haxe.Constraints.Function;
import electron.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class BaseIpcCommands {
    /* Constructor Function */
    public function new():Void {
        _pb = new EventDispatcher();
        @:privateAccess _pb.__checkEvents = false;
        _replyListeners = new Dict();
        _listened = new Set();
    }

/* === Utility Methods === */

    public inline function push(channel: String):Void {
        send(channel, null, null);
    }

    /**
      * bind a function to a channel
      */
    public function fbind(exportName:String, func:Function, sendReturn:Bool=false):Void {
        on(exportName, function(packet) {
            var args:Array<Dynamic> = cast packet.data;
            if (args == null) {
                args = [];
            }
            var result:Dynamic = Reflect.callMethod(null, func, args);
            if ( sendReturn ) {
                packet.reply( result );
            }
        });
    }



/* === Instance Methods === */

    /**
      * listen for a message on a particular channel
      */
    public function _onMessage(channel:String, handler:Dynamic->Void):Void {
        return ;
    }

    /**
      * post a message
      */
    public function _post(channel:String, data:Dynamic):Void {
        return ;
    }

    /**
      * handle a reply-packet
      */
    public inline function _onReply(reply: WorkerPacket):Void {
        var replyToId:String = reply.type.after( WorkerPacket.REPLYPREFIX );
        if (_replyListeners.exists( replyToId )) {
            var entry = _replyListeners[replyToId];
            entry.listener( reply.data );
        }
    }

    /**
      * listen for messages on a given channel
      */
    public function _listenForMessage(channel:String, allowsReply:Bool=false):Void {
        if (_listened.exists( channel )) {
            return ;
        }

        _onMessage(channel, function(data: Dynamic) {
            if (isPacket( data )) {
                var packet:WorkerPacket = cast data;
                packet = packet.decode();

                if (packet.type.startsWith( WorkerPacket.REPLYPREFIX )) {
                    trace('REPLY');
                    trace( packet );
                    return _onReply( packet );
                }

                var ipacket:IpcIncomingPacket = new IpcIncomingPacket(this, packet);
                _pb.dispatch(ipacket.type, ipacket);
            }
            else {
                trace( data );
            }
        });

        _listened.push( channel );
    }

    /**
      * listen for an incoming packet
      */
    public function on(channel:String, handler:IpcIncomingPacket->Void):Void {
        _listenForMessage( channel );
        _pb.on(channel, handler);
    }

    /**
      * listen for an incoming packet
      */
    public function once(channel:String, handler:IpcIncomingPacket->Void):Void {
        _listenForMessage( channel );
        _pb.once(channel, handler);
    }

    /**
      * send a packet outgoing
      */
    public function send(channel:String, data:Dynamic, ?encoding:WorkerPacketEncoding, ?onResponse:Dynamic->Void):Void {
        var packet:WorkerPacket = pack(channel, data, encoding);
        if (onResponse != null) {
            _replyListeners[packet.id] = {
                packet: packet,
                listener: onResponse
            };

            _listenForMessage(WorkerPacket.REPLYPREFIX + packet.id);
        }
        _post(packet.type, packet);
    }

    /**
      * create and return a new packet
      */
    private inline function pack(type:String, data:Dynamic, ?encoding:WorkerPacketEncoding):WorkerPacket {
        if (encoding == null) {
            encoding = WorkerPacketEncoding.None;
        }
        return new WorkerPacket({
            type: type,
            encoding: encoding,
            data: data
        });
    }

    /**
      * determine whether the given anonymous object is a packet
      */
    private inline function isPacket(o : Dynamic):Bool {
        return (
            (o.type != null && (o.type is String)) &&
            (o.encoding != null && WorkerPacketEncoding.isWorkerPacketEncoding( o.encoding ))
        );
    }

/* === Instance Fields === */

    // packet broadcaster
    public var _pb: EventDispatcher;

    // streams
    public var _replyListeners: Dict<String, {packet:WorkerPacket, listener:Dynamic->Void}>;
    private var _listened: Set<String>;
}
