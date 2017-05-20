package pman.ww;

import haxe.Json as JSON;
import haxe.Serializer;
import haxe.Unserializer;

@:forward
abstract WorkerPacket (TWorkerPacket) from TWorkerPacket to TWorkerPacket {
    /* Constructor Function */
    public inline function new(wp : TWorkerPacket):Void {
        this = wp;
    }

/* === Methods === */

    /**
      * check whether [this] packet is encoded
      */
    public inline function isEncoded(?t : WorkerPacketEncoding):Bool {
        return ((t != null ? t : this.encoding) != None);
    }

    /**
      * create a clone of [this] packet
      */
    public inline function clone():WorkerPacket {
        return new WorkerPacket({
            type: this.type,
            encoding: this.encoding,
            data: this.data
        });
    }

    /**
      * encode an unencoded packet
      */
    public function encode(etype : WorkerPacketEncoding):WorkerPacket {
        var copy:WorkerPacket = clone();
        //var etype:WorkerPacketEncoding = (type == null ? this.encoding : type);
        if (!isEncoded()) {
            switch ( etype ) {
                case Json:
                    copy.encoding = Json;
                    copy.data = JSON.stringify( this.data );

                case Haxe:
                    copy.encoding = Haxe;
                    copy.data = Serializer.run( this.data );

                default:
                    null;
            }
        }
        else {
            throw 'Error: Packet is already encoded';
        }
        return copy;
    }

    /**
      * convert (if necessary) into a unencoded packet
      */
    public function decode():WorkerPacket {
        switch ( this.encoding ) {
            case Json:
                return {
                    type: this.type,
                    encoding: None,
                    data: JSON.parse(untyped this.data)
                };

            case Haxe:
                return {
                    type: this.type,
                    encoding: None,
                    data: Unserializer.run(untyped this.data)
                };

            case None:
                return this;
        }
    }

    /**
      * check whether the given anonymous object is a packet
      */
    public static inline function isPacket(o : Dynamic):Bool {
        return (
            (o.type != null && (o.type is String)) &&
            (o.encoding != null && WorkerPacketEncoding.isWorkerPacketEncoding( o.encoding ))
        );
    }
}

typedef TWorkerPacket = {
    type: String,
    encoding: WorkerPacketEncoding,
    data: Dynamic
};

@:enum
abstract WorkerPacketEncoding (String) from String to String {
    var None = 'none';
    var Json = 'json';
    var Haxe = 'haxe';

    public static inline function isWorkerPacketEncoding(s : String):Bool {
        return (
            (s == None) ||
            (s == Json) ||
            (s == Haxe)
        );
    }
}
