package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

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

class BuildStandalones extends BatchTask {
    public function new(o : TaskOptions):Void {
        super();

        o.platforms = o.platforms.unique();
        o.arches = o.arches.unique();

        inline function q(t:Task)
            children.push( t );

        for (platform in o.platforms) {
            var appClass:Class<PackStandalone> = (switch ( platform ) {
                case 'linux', 'ubuntu': LinuxApp;
                case 'win32', 'windows': WindowsApp;
                default: PackStandalone;
            });
            for (arch in o.arches) {
                var pack = Type.createInstance(appClass, untyped [o, arch]);
                q( pack );
            }
        }
    }
}
