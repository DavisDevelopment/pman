package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import pack.PackStandalone as Ps;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class BuildInstallers extends BatchTask {
    public function new(o : TaskOptions):Void {
        super();

        for (platform in o.platforms) {
            for (arch in o.arches) {
                switch ( platform ) {
                    case 'linux':
                        addChild(new DebianInstaller( arch ));

                    case 'win32', 'windows':
                        addChild(new WindowsInstaller( arch ));

                    default:
                        throw 'Error: $platform platform not yet supported';
                }
            }
        }
    }
}
