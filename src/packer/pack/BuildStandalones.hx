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

        inline function q(t:Task)
            children.push( t );

        for (platform in o.platforms) {
            for (arch in o.arches) {
                switch ( platform ) {
                    case 'linux':
                        q(new LinuxApp( arch ));

                    case 'win32', 'windows':
                        q(new WindowsApp( arch ));

                    default:
                        throw 'Error: $platform platform not yet supported';
                }
            }
        }
    }
}
