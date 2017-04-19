package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

@:structInit
class TaskOptions {
/* === Instance Methods === */

    /**
      * check for existence of flag
      */
    public function hasFlag(flag : String):Bool {
        return flags.exists( flag );
    }

    /**
      * get the value associated with a given flag
      */
    public function getFlag<T>(flag : String):Maybe<T> {
        return flags[flag];
    }

    /**
      * set a flag
      */
    public function setFlag<T>(flag:String, value:T):T {
        return (flags[flag] = value);
    }

/* === Instance Fields === */

    public var release : Bool;
    public var compress : Bool;
    public var concat : Bool;
    public var platforms : Array<String>;
    public var arches : Array<String>;
    public var directives : Array<String>;
    public var flags : Dict<String, Dynamic>;
    public var styles : StylesOpts;
    public var scripts : ScriptsOpts;
    public var app : AppOpts;
}

typedef AssetOpts = {
    compile : Bool,
    compress : Bool,
    concat : Bool
};

typedef StylesOpts = {
    >AssetOpts,
};

typedef ScriptsOpts = {
    >AssetOpts,
};

typedef AppOpts = {
    compile : Bool,
    haxeDefs : Array<String>
};
