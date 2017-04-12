package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

class LaunchInfo {
    public var cwd : Path;
    public var argv : Array<String>;
    public var env : Map<String, String>;
    public function new(cwd:Path, argv:Array<String>, env:Map<String,String>):Void {
        this.cwd = cwd;
        this.argv = argv;
        this.env = env;
    }

    public static function fromRaw(raw : RawLaunchInfo):LaunchInfo {
        var cwd = Path.fromString( raw.cwd );
        var env:Map<String, String> = new Map();
        for (key in Reflect.fields( raw.env )) {
            env[key] = Std.string(Reflect.getProperty(raw.env, key));
        }
        return new LaunchInfo(cwd, raw.argv, env);
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
    argv: Array<String>,
    cwd: String,
    env: Dynamic
};
