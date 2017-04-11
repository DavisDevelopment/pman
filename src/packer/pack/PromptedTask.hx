package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PromptedTask extends Task {
    /* Constructor Function */
    public function new():Void {

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
            super.run( cb );
        });
    }

/* === Instance Fields === */

}
