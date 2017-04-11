package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Task {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    public function run(?cb : ?Dynamic->Void):Void {
        if (cb == null) {
            cb = (function(?error : Dynamic) null);
        }
        execute( cb );
    }

    /**
      * execute [this] Task
      */
    private function execute(cb : ?Dynamic->Void):Void {
        cb();
    }

/* === Instance Fields === */
}
