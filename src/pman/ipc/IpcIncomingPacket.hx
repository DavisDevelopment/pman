package pman.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import edis.concurrency.*;
import edis.concurrency.WorkerPacket;

import haxe.extern.EitherType;
import electron.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class IpcIncomingPacket {
    /* Constructor Function */
    public function new(owner:BaseIpcCommands, packet:WorkerPacket):Void {
        this.ipc = owner;
        this.packet = packet;

        id = packet.id;
        type = packet.type;
        data = packet.data;
    }

/* === Instance Methods === */

    /**
      * reply to [this] packet
      */
    public function reply(data:Dynamic, ?encoding:WorkerPacketEncoding):Void {
        var resPacket:WorkerPacket = new WorkerPacket({
            id: id,
            type: (WorkerPacket.REPLYPREFIX + id),
            data: data,
            encoding: None
        });
        resPacket = resPacket.encode((encoding != null) ? encoding : packet.encoding);

        ipc._post(resPacket.type, resPacket);
    }

/* === Instance Fields === */

    public var id(default, null): String;
    public var type(default, null): String;
    public var data(default, null): Dynamic;

    private var ipc: BaseIpcCommands;
    private var packet: WorkerPacket;
}
