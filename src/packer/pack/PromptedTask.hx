package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class PromptedTask extends pack.Task {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * Prompt the user for input regarding [this] Task
      */
    public function prompt(done : Void->Void):Void {
        done();
    }

    /**
      * run [this] Task
      */
    override function run(?cb : ?Dynamic->Void):Void {
        prompt(function() {
            if (cb == null) {
                cb = (function(?error : Dynamic) null);
            }
            execute( cb );
        });
    }

/* === Instance Fields === */

}
