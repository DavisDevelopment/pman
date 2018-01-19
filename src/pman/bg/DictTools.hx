package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.ds.dict.DictKey;

import pman.bg.media.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;

import Slambda.fn;
import tannus.FunctionTools as Ft;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

class DictTools {
    /**
      * perform a 'reduce' operation on [d]
      */
    public static function reduce<K:DictKey, V, Out>(d:Dict<K,V>, handler:Out->K->V->Out, acc:Out):Out {
        for (key in d.keys()) {
            acc = handler(acc, key, d[key]);
        }
        return acc;
    }

    @:generic
    public static function copy<K:DictKey>(d: Dict<K, Dynamic>):Dict<K, Dynamic> {
        var c = new Dict();
        for (k in d.keys()) {
            c.set(k, d.get(k));
        }
        return c;
    }
}

class StringDictTools {
    /**
      * build a Dict<String, T> from an Object
      */
    public static function toDict(o:Dynamic, ?map_key:String->String, ?map_value:Dynamic->Dynamic):Dict<String, Dynamic> {
        if (map_key == null) map_key = Ft.identity;
        if (map_value == null) map_value = Ft.identity;
        var o:Object = o;
        var res:Dict<String, Dynamic> = new Dict();
        for (key in o.keys) {
            res[map_key( key )] = map_value(o[key]);
        }
        return res;
    }

    /**
      * convert a Dict<String, T> to an anonymous Object
      */
    public static function toAnon(d:Dict<String,Dynamic>, ?map_key:String->String, ?map_value:Dynamic->Dynamic):Dynamic {
        if (map_key == null) map_key = Ft.identity;
        if (map_value == null) map_value = Ft.identity;
        var o:Object = {};
        for (key in d.keys()) {
            o.set(map_key( key ), map_value(d.get( key )));
        }
        return o;
    }
}
