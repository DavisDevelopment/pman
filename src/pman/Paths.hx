package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

import tannus.math.TMath.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Paths {
/* === Static Methods === */

    public static function home():Path {
        if (_home == null) {
            _home = new Path(Sys.getEnv(os() == 'Windows' ? 'USERPROFILE' : 'HOME'));
        }
        return _home;
    }

    public static function subhome(sub : String):Path {
        return home().plusString( sub ).normalize();
    }

    public static function appData():Path {
        if (_appData == null) {
            switch (os()) {
                case 'Linux':
                    _appData = (home().plusString( '.config' ));

                case 'Darwin':
                    _appData = (home().plusString('Library/Application Support'));

                case 'Windows':
                    _appData = new Path(Sys.getEnv( 'APPDATA' ));

                default:
                    _appData = (home().plusString('.pman'));
            }
        }
        return _appData;
    }

    public static function userData():Path {
        if (_userData == null) {
            _userData = (appData().plusString( APPNAME ));
        }
        return _userData;
    }

    public static function library(lib:Library):Path {
        if (_libs == null)
            _libs = new Dict();
        if (_libs.exists( lib )) {
            return _libs[lib];
        }
        else {
            var path : Path;
            switch ( lib ) {
                case Documents:
                    path = subhome('Documents');

                case Downloads:
                    path = subhome('Downloads');

                case Pictures:
                    path = subhome('Pictures');

                case Videos:
                    path = subhome('Videos');

                case Music:
                    path = subhome('Music');
            }

            // cater to Windows xp
            if (!Fs.exists( path )) {
                var path2 = path.directory.plusString('My ' + path.basename);
                if (Fs.exists( path2 )) {
                    path = path2;
                }
                else {
                    throw 'Error: Library path for $lib is not accurate';
                }
            }

            return (_libs[lib] = path);
        }
    }

    public static function documents():Path return library(Documents);
    public static function downloads():Path return library(Downloads);
    public static function pictures():Path return library(Pictures);
    public static function videos():Path return library(Videos);
    public static function music():Path return library(Music);
    public static function getLibraryPath(library: Int):Path {
        return Paths.library(Library.createByIndex(library));
    }

    public static function appPath():Path {
        if (_app == null) {
            //_app = electron.ext.App.getAppPath();
            _app = (new Path(untyped __js__('__dirname') + '')).plusString('../').normalize();
            if (!Fs.exists(_app.plusString('package.json'))) {
                throw 'Sanity Check Failed: $_app is not the application path';
            }
        }
        return _app;
    }

    private static function os():String {
        if (_os == null)
            _os = Sys.systemName();
        return _os;
    }

/* === Static Fields === */

    private static var _home : Null<Path> = null;
    private static var _app : Null<Path> = null;
    private static var _appData : Null<Path> = null;
    private static var _userData : Null<Path> = null;
    private static var _libs : Null<Dict<Library, Path>> = null;
    private static var _os : Null<String> = null;

    private static inline var APPNAME:String = 'pman';
}

enum Library {
    Documents;
    Pictures;
    Music;
    Videos;
    Downloads;
    //Trash;
}
