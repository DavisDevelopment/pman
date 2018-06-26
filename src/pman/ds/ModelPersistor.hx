package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.events.EventEmitter;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;
import haxe.rtti.Meta;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.macro.MacroTools;

/**
  used to persist a Model object onto some storage medium
 **/
class ModelPersistor <T:Model> {
    /* Constructor Function */
    public function new(m: T):Void {
        this.model = m;
        this.saveInfo = _info_(cast Type.getClass(m));
    }

/* === Instance Methods === */

    static inline function _info_(cl: Class<Model>):ModelSaveInfo {
        var res = pinf( cl );
        //TODO any reasonably necessary tweaks to the object
        return res;
    }

    /**
      extract a partial save-info object from [cl]
     **/
    static inline function pinf(cl: Class<Model>):ModelSaveInfo {
        var m = meta( cl );
        return m == null ? null : {
            name: (m.exists('saveName') ? m['saveName'].join('') : null),
            version: version(m['version'])
        };
    }

    /**
      extract raw metadata from the given class
     **/
    static inline function meta<T>(c: Class<T>):Anon<Array<Dynamic>> {
        return Meta.getType( c );
    }

    /**
      get the 'version' number for a model
     **/
    static function version(x: Null<Array<Dynamic>>):Float {
        if (x.empty()) {
            return -1;
        }
        else if (x.length == 1) {
            var vernum = x[0];
            if ((vernum is Float)) {
                return (vernum: Float);
            }
            else if ((vernum is String)) {
                return Std.parseFloat(cast vernum);
            }
            else {
                throw 'TypeError: Invalid version number';
            }
        }
        else {
            throw 'TypeError: @version($x) has too many arguments. Only 1 is required';
        }
    }

/* === Instance Fields === */

    var model: T;
    var modem: Modem<ByteArray, T>;

    public var saveInfo: ModelSaveInfo;
}

typedef ModelSaveInfo = {
    ?name: String,
    ?version: Float
};
