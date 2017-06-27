package pman.db;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import haxe.Constraints.Function;

import pman.db.Modem;
import pman.db.AppDir;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaIdCache {
    /* Constructor Function */
    public function new():Void {
        o = null;
        m = new JsonModem();
        var path:Path = bpmain.appDir.mediaIdCachePath();
        if (!Fs.exists( path )) {
            Fs.write(path, '{}');
        }
        m.port = new TextFilePort( path );
    }

/* === Instance Methods === */

    /**
      * attempt to collect the ids for the tracks referenced in the list of URIs given
      */
    public function get(uris : Array<String>):Map<String, Int> {
        o = m.read();
        var res = new Map();
        for (uri in uris) {
            var id = getId( uri );
            if (id != null)
                res[uri] = id;
        }
        o = null;
        return res;
    }

    /**
      * attempt to obtain a single id
      */
    public function getId(uri : String):Null<Int> {
        return Reflect.getProperty((o!=null?o:m.read()), uri);
    }

    /**
      * add newly obtained ids to the cache
      */
    public function set(ids : Map<String, Int>) {
        m.edit(function(o : Object) {
            for (uri in ids.keys()) {
                o[uri] = ids[uri];
            }
        });
    }

    /**
      * remove entry entirely
      */
    public function remove(uris : Array<String>) {
        m.edit(function(o : Object) {
            for (uri in uris)
                o.remove( uri );
        });
    }

/* === Instance Fields === */
    
    private var m : JsonModem<Object>;
    private var o : Null<Dynamic>;
}
