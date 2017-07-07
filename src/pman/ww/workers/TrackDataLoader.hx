package pman.ww.workers;

import pman.db.MediaIdCache;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TrackDataLoader extends Worker {
    override function onPacket(packet : WorkerPacket):Void {
        switch ( packet.type ) {
            case 'getids':
                send('ids', getIds( packet.data ));

            default:
                null;
        }
    }

    private function getIds(sources : Array<String>):Array<Null<Int>> {
        var ids:Array<Null<Int>> = new Array();
        var cache = new MediaIdCache();
        var m = cache.get( sources );
        for (src in sources) {
            ids.push(m[src]);
        }
        return ids;
    }
}
