packag ;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Packer extends Application {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * start pack
      */
    override function start():Void {
        trace('weiners');
    }

/* === Instance Fields === */

    public var tasks : Array<Task>;

/* === Static Methods === */

    public static function main():Void {
        new Packer().start();
    }
}
