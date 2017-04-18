package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class WindowsInstaller extends Installer {
    /* Constructor Function */
    public function new(arch:String):Void {
        super('win32', arch);
    }

/* === Instance Methods === */

    // run the 'build' function
    override function runBuild(callback : ?Dynamic->Void):Void {
        var resultPromise = build.createWindowsInstaller( options );
        function success():Void {
            trace('it fucking worked! :D');
            callback();
        }
        function failure(error:Dynamic):Void {
            trace( error );
            callback( error );
        }
        trace( resultPromise );
        resultPromise.then(success, failure);
    }

    // get the 'build' function
    override function getBuildFunction():Dynamic {
        //return require('electron-installer-windows');
        return require('electron-winstaller');
    }

    // get the 'icon' field value
    override function getIcon():Dynamic {
        return (path('assets/icon32.ico').toString());
    }

    // build the 'options' field
    override function buildOptions():Void {
        options = {
            appDirectory: (path('releases/pman-win32-$arch').toString()),
            outputDirectory: (path('installers').toString()),
            setupIcon: getIcon()
        };
    }
}
