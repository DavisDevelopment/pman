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

typedef TaskOptions = {
    release:Bool,
    compress:Bool,
    concat:Bool,
    platforms:Array<String>,
    arches:Array<String>,
    styles: {
        compile: Bool,
        compress: Bool,
        concat: Bool
    },
    scripts: {
        compile: Bool,
        compress: Bool,
        concat: Bool
    },
    app: {
        compile: Bool,
        haxeDefs: Array<String>
    },
    directives: Array<String>
};
