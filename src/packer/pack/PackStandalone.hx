package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class PackStandalone extends Task {
    /* Constructor Function */
    public function new(o:TaskOptions, platform:String, arch:String='x64', ?opts:Array<PackagerOptions>):Void {
        super();

        this.go = o;
        this.platform = platform;
        this.arch = arch;
        this.options = buildOptions(opts != null ? opts : []);
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : ?Dynamic->Void):Void {
        var rawOptions = toRaw( options );
        function packCb(error:Null<Dynamic>, appPaths:Array<String>):Void {
            if (error != null) {
                done( error );
            }
            else {
                var bundlePath = Path.fromString(appPaths[0]);
                afterBundle(bundlePath, function() {
                    done();
                });
            }
        }
        pack(rawOptions, packCb);
    }

    /**
      * called after [pack] has finished
      */
    private function afterBundle(path:Path, done:Void->Void):Void {
        done();
    }

    /**
      * called on copy of application
      */
    private function afterCopy(path:Path, electronVersion:String, platform:String, arch:String, done:Void->Void):Void {
        done();
    }

    /**
      * paths for which [ignore] returns true are ignored
      */
    private function ignore():String->Bool {
        var sglobs:Array<String> = [
            'buildscripts[/*]',
            'releases[/*]',
            'installers[/*]',
            'styles/widgets',
            'styles/*.less',
            '*.xcf',
            "build.sh",
            "package.sh",
            "prefixer.py"
        ];
        var globs:Array<GlobStar> = sglobs.map.fn(GlobStar.fromString(_));

        return (function(spath : String):Bool {
            var path:Path = new Path(spath.after('/'));
            for (glob in globs) {
                if (glob.test(path.toString())) {
                    return true;
                }
            }
            return false;
        });
    }

    /**
      * build and return a PackagerOptions object
      */
    private function buildOptions(ol : Array<Dynamic>):PackagerOptions {
        var result:PackagerOptions = {
            name: 'pman',
            appname: 'pman',
            arch: arch,
            platform: platform,
            icon: path('assets/icon32.png'),
            version: '1.6.2',
            dir: path(),
            sourcedir: path(),
            out: path( 'releases' ),
            overwrite: true,
            asar: false,
            prune: true,
            app_version: null,
            afterCopy: [afterCopy],
            ignore: ignore()
        };
        var imgExt:String = (switch ( platform ) {
            case 'win32': 'ico';
            default: 'png';
        });
        result.icon = path('assets/icon32.$imgExt');
        var o:Object = result;
        for (x in ol) {
            o.write( x );
        }
        return result;
    }

    /**
      * convert a PackagerOptions to a RawPackagerOptions
      */
    private function toRaw(o : PackagerOptions):RawPackagerOptions {
        inline function maybe<T>(x : Null<T>):Maybe<T> return x;
        inline function pon(x : Null<Path>):Null<String> {
            return maybe(x).ternary(_.toString(), null);
        }
        var raw:RawPackagerOptions = {
            name: o.name,
            appname: o.appname,
            arch: o.arch,
            platform: o.platform,
            icon: pon( o.icon ),
            version: o.version,
            dir: pon( o.dir ),
            sourcedir: pon( o.sourcedir ),
            out: pon( o.out ),
            overwrite: o.overwrite,
            asar: o.asar,
            prune: o.prune,
            app_version: o.app_version,
            afterCopy: [],
            afterExtract: [],
            ignore: o.ignore
        };
        if (o.afterCopy != null) {
            for (f in o.afterCopy) {
                raw.afterCopy.push(function(buildPath:String, electronVersion:String, platform:String, arch:String, done:Void->Void) {
                    f(Path.fromString(buildPath), electronVersion, platform, arch, done);
                });
            }
        }
        return raw;
    }

/* === Instance Fields === */

    public var go : TaskOptions;
    public var platform : String;
    public var arch : String;
    public var options : PackagerOptions;

/* === Static Fields === */

    // the 'electron-packager' module
    private static var pack:Dynamic = {require('electron-packager');};
}

typedef RawPackagerOptions = {
    ?name:String,
    ?appname:String,
    ?arch:String,
    ?platform:String,
    ?icon:String,
    ?version:String,
    ?dir:String,
    ?sourcedir:String,
    ?out:String,
    ?overwrite:Bool,
    ?asar:Bool,
    ?prune:Bool,
    ?app_version:String,
    ?ignore:Dynamic,
    ?afterCopy:Array<String->String->String->String->(Void->Void)->Void>,
    ?afterExtract:Array<String->String->String->String->(Void->Void)->Void>
};

typedef PackagerOptions = {
    ?name:String,
    ?appname:String,
    ?arch:String,
    ?platform:String,
    ?icon:Path,
    ?version:String,
    ?dir:Path,
    ?sourcedir:Path,
    ?out:Path,
    ?overwrite:Bool,
    ?asar:Bool,
    ?prune:Bool,
    ?app_version:String,
    ?ignore:Dynamic,
    ?afterCopy:Array<Path->String->String->String->(Void->Void)->Void>,
    ?afterExtract:Array<Path->String->String->String->(Void->Void)->Void>
};
