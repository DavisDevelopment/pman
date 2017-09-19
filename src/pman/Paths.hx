package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
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
            _home = new Path(Sys.getEnv(os() == 'Win32' ? 'USERPROFILE' : 'HOME'));
        }
        return _home;
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

    private static function os():String {
        if (_os == null)
            _os = Sys.systemName();
        return _os;
    }

/* === Static Fields === */

    private static var _home : Null<Path> = null;
    private static var _appData : Null<Path> = null;
    private static var _userData : Null<Path> = null;
    private static var _os : Null<String> = null;

    private static inline var APPNAME:String = 'pman';
}
