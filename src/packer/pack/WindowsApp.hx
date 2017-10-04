package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import pack.PackStandalone;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class WindowsApp extends PackStandalone {
    /* Constructor Function */
    public function new(o:TaskOptions, arch:String, ?opts:Array<PackagerOptions>):Void {
        super(o, 'win32', arch, opts);
    }
}
