package pman.ww.workers;

import tannus.ds.*;
import tannus.io.*;

import pman.async.*;
import pman.async.ReadStream;
import pman.ww.WorkerStream;
import pman.ww.workers.*;
import pman.ww.workers.HDDProbeInfo;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class HDDProbeStream<T> extends WorkerStream<HDDSProbeInfo, Array<T>> {
    /* Constructor Function */
    public function new(name:String, ?type:BossType, ?info:HDDSProbeInfo):Void {
        super();

        this.name = name;
        this.bossType = (type == null ? WebWorker : type);
        this.i = {
            paths: []
        };
        if (info != null)
            this.i = info;
    }

/* === Instance Methods === */

/* === Computed Instance Fields === */

    public var paths(get, set):Array<String>;
    private inline function get_paths() return i.paths;
    private inline function set_paths(v) return (i.paths = v);

    public var filter(get, set):Null<String>;
    private inline function get_filter() return i.filter;
    private inline function set_filter(v) return (i.filter = v);

    public var sort(get, set):Null<String>;
    private inline function get_sort() return i.sort;
    private inline function set_sort(v) return (i.sort = v);
}
