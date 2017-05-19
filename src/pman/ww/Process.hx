package pman.ww;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import ida.*;
import ida.backend.idb.*;

import pman.ww.WorkerPacket;
import pman.ww.WorkerPacket as Packet;

import pman.media.MediaSource;
import pman.db.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using pman.media.MediaTools;

class Process extends Worker {
    /* Constructor Function */
    private function new() {
        super();

        ps = new EventDispatcher();
        @:privateAccess ps.__checkEvents = false;
    }

/* === Instance Methods === */

    override function __start():Void {
        __listen__();

        super.__start();
    }

    /**
      * handle incoming packets
      */
    override function onPacket(packet : Packet):Void {
        // broadcast [packet] on [ps]
        ps.dispatch(packet.type, packet.data);
    }

    /**
      * initialize handlers
      */
    private function __listen__():Void {
        //TODO listen for input
    }

    private inline function on<T>(t:String, f:T->Void):Void ps.on(t, f);
    private inline function once<T>(t:String, f:T->Void):Void ps.once(t, f);
    private inline function when<T>(t:String, c:T->Bool, f:T->Void):Void ps.when(t, c, f);

    private var ps:EventDispatcher;
}
