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

class WindowsInstaller extends Installer {
    /* Constructor Function */
    public function new(arch:String):Void {
        super('win32', arch);
    }

    override function getBuildFunction():Dynamic {
        return require('electron-installer-windows');
    }

    override function getIcon():Dynamic {
        return (path('assets/icon32.ico').toString());
    }
}
