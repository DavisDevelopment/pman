package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class BatchTask extends Task {
    public function new(?kids : Iterable<Task>):Void {
        super();

        if (kids != null) {
            for (t in kids) {
                addChild( t );
            }
        }
    }

    override function execute(done : VoidCb):Void {
        done();
    }
}
