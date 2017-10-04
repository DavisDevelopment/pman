package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.VoidAsyncs;

class Task extends Task1 {
    /* Constructor Function */
    public function new():Void {
        super();

        children = new Array();
    }

/* === Instance Methods === */

    /**
      * run [this] Task
      */
    override function run(?callback : VoidCb):Void {
        if (callback == null) {
            callback = (function(?error) if (error != null) throw error);
        }
        execute(function(?error) {
            if (error != null || children.empty()) {
                callback ( error );
            }
            else {
                Tools.batch(children, callback);
            }
        });
    }

    /**
      * add a child-task to [this]
      */
    public function addChild(task : Task):Void {
        children.push( task );
    }

    /**
      * create and return a clone of [this] Task
      */
    public function clone():Task {
        var copy:Task = Type.createEmptyInstance(Type.getClass( this ));
        copy.children = children.map.fn(_.clone());
        return copy;
    }

/* === Instance Fields === */

    public var children : Array<Task>;
}
