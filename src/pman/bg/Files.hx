package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import Slambda.fn;

import pman.Paths;
import pman.Paths.Library;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using pman.bg.MediaTools;

class Files {
/* === Methods === */

    public static function subData(name: String):Path {
        return Paths.appData().plusString(name);
    }

/* === Variables === */

}
