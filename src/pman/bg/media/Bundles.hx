package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.http.Url;

import pman.bg.db.*;
import pman.bg.tasks.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;
import pman.bg.media.*;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using pman.bg.MediaTools;

class Bundles {
    public static function getRootBundlePath():Path {
        if (_rbp == null) {
            return (_rbp = Dirs.documentPaths()[0]);
        }
        return _rbp;
    }

    private static inline function assertDir(path: Path):Path {
        if (!Fs.exists( path )) {
            Fs.createDirectory( path );
        }
        return path;
    }

    public static inline function assertRootBundlePath():Path {
        return assertDir(getRootBundlePath());
    }

    public static inline function getBundlePath(name: String):Path {
        return getRootBundlePath().plusString('$name.bundle');
    }

    public static function assertBundlePath(name: String):Path {
        return assertDir(assertRootBundlePath().plusString('$name.bundle'));
    }

/* === Variables === */

    // root bundle path
    private static var _rbp:Null<Path> = null;
}
