package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import gryffin.display.Image;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Bundle {
    /* Constructor Function */
    public function new(title : String):Void {
        this.title = title;
        this.path = Bundles.assertBundlePath( title );
    }

/* === Instance Methods === */

    /**
      * obtain list of subpaths of the bundle
      */
    public function subpaths():Array<Path> {
        return fnl().map.fn(path.plusString( _ ));
    }

    /**
      * get list of file names
      */
    private function fnl():Array<String> {
        return Fs.readDirectory( path );
    }

/* === Instance Fields === */

    public var title : String;
    public var path : Path;
}
