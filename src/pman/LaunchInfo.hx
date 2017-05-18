package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

using Slambda;

class LaunchInfo {
    public var cwd : Path;
    public var env : Map<String, String>;
    public var paths : Array<Path>;

    public function new():Void {
        cwd = new Path('/');
        env = new Map();
        paths = new Array();
    }

    public static function fromRaw(raw : RawLaunchInfo):LaunchInfo {
        var cwd = Path.fromString( raw.cwd );
        var env:Map<String, String> = new Map();
        for (key in Reflect.fields( raw.env )) {
            env[key] = Std.string(Reflect.getProperty(raw.env, key));
        }
        var paths:Array<Path> = raw.paths.map.fn(new Path(_));
        var i = new LaunchInfo();
        i.cwd = cwd;
        i.env = env;
        i.paths = paths;
        return i;
    }
}

/*
typedef LaunchInfo = {
    argv: Array<String>,
    cwd: Path,
    env: Map<String, String>
};
*/

typedef RawLaunchInfo = {
    paths: Array<String>,
    cwd: String,
    env: Dynamic
};
