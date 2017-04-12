package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;
import pack.PackStandalone as Ps;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class BuildStandalones extends BatchTask {
    public function new(o : TaskOptions):Void {
        super();

        children.push(new Ps('linux', 'x64'));
        children.push(new Ps('win32', 'x64'));
    }
}
