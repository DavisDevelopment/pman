package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

using Slambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.FunctionTools;
using tannus.ds.MapTools;

/**
  models information sent to the renderer process at launch
 **/
class LaunchInfo {
    /* Constructor Function */
    public function new(?cwd:String, ?argv:Array<String>, ?env:Dynamic):Void {
        this.cwd = new Path(cwd != null ? cwd : '/');
        this.env = (env == null ? new Map() : cast (new Object( env ).toMap()));
        this.argv = (argv == null ? [] : argv);

        _sanitize();
    }

/* === Instance Methods === */

    /**
      create and return an exact copy of [this]
     **/
    public inline function clone():LaunchInfo {
        return new LaunchInfo(cwd.toString(), argv.copy(), env.toObject());
    }

    /**
      sanitize [this] LaunchInfo, inplace
     **/
    function _sanitize() {
        this.cwd = this.cwd.normalize();
        this.argv = this.argv.map.fn(_.nullEmpty()).compact();
    }

    /**
      create a new LaunchInfo from a raw Json object
     **/
    public static inline function fromRaw(raw : RawLaunchInfo):LaunchInfo {
        return new LaunchInfo(
            raw.cwd,
            raw.argv,
            raw.env
        );
    }

/* === Instance Fields === */

    public var cwd: Path;
    public var env: Map<String, String>;
    public var argv: Array<String>;
}

typedef RawLaunchInfo = {
    argv: Array<String>,
    cwd: String,
    env: Dynamic
};
