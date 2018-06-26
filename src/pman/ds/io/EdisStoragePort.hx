package pman.ds.io;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import edis.storage.kv.*;
import edis.storage.kv.StorageArea;

import pman.ds.Port;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class EdisStoragePort<T> extends Port<T> {
    /* Constructor Function */
    public function new(area:StorageArea, key:String):Void {
        super();

        this.area = area;
        this.key = key;
    }

/* === Instance Methods === */

    override function initialize(?cb: VoidCb):VoidPromise {
        return area.initialize.toPromise().toAsync( cb );
    }

    override function read(?cb: Cb<T>):Promise<T> {
        return area.getValue.bind(key, _).toPromise().toAsync( cb );
    }

    override function write(value:T, ?cb:VoidCb):VoidPromise {
        return area.setValue.bind(key, value, _).toPromise().toAsync( cb );
    }

    override function delete(?cb: VoidCb):VoidPromise {
        return area.removeProperty.bind(key, _).toPromise().toAsync( cb );
    }

/* === Instance Fields === */

    var area: StorageArea;
    var key: String;
}
