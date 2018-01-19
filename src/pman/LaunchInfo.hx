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

class LaunchInfo {
    public var cwd: Path;
    public var env: Map<String, String>;
    public var argv: Array<String>;

    public function new(?cwd:String, ?argv:Array<String>, ?env:Map<String, String>):Void {
        this.cwd = new Path(cwd != null ? cwd : '/');
        this.env = (env == null ? new Map() : env);
        this.argv = (argv == null ? [] : argv);
    }

    public static function fromRaw(raw : RawLaunchInfo):LaunchInfo {
        return new LaunchInfo(raw.cwd, raw.argv, raw.env);
    }
}

typedef RawLaunchInfo = {
    argv: Array<String>,
    cwd: String,
    env: Dynamic
};
