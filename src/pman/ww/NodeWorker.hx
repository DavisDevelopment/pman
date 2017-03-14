package pman.ww;

import tannus.node.ChildProcess;
import pman.ww.WorkerPacket;

class NodeWorker extends Worker {
    private var p : ChildProcess;
    public function new(cp : ChildProcess):Void {
        super();
        p = cp;
    }

    override function send(type:String, data:Dynamic, encoding:WorkerPacketEncoding=None):Void {
        p.send(packet(type, data, encoding));
    }

    override function kill():Void p.kill();

    override function _onMessage(f : Dynamic->Void):Void {
        p.on('message', f);
    }
}
