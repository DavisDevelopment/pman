package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import electron.ext.App;
import electron.ext.ExtApp;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Bundles {
    /**
      * get the root bundle path
      */
    public static function getRootBundlePath():Path {
        return App.getPath(Documents).plusString('.pman_bundles');
    }

    /**
      * assert that the root bundle path exists
      */
    public static function assertRootBundlePath():Path {
        var root = getRootBundlePath();
        if (!Fs.exists( root )) {
            Fs.createDirectory( root );
        }
        return root;
    }

    /**
      * get the path to a bundle by name
      */
    public static function getBundlePath(name : String):Path {
        return getRootBundlePath().plusString(name + '.bundle');
    }

    /**
      * assert that a bundle path exists
      */
    public static function assertBundlePath(name : String):Path {
        assertRootBundlePath();
        var bundlePath:Path = getBundlePath( name );
        if (!Fs.exists( bundlePath )) {
            Fs.createDirectory( bundlePath );
        }
        return bundlePath;
    }

    /**
      * create and return a new Bundle instance
      */
    public static function getBundle(name : String):Bundle {
        return new Bundle( name );
    }
}
