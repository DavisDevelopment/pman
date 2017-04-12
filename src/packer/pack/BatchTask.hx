package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class BatchTask extends Task {
    private var children:Array<Task>;
    public function new(?tasks:Array<Task>):Void {
        super();

        children = (tasks != null ? tasks : []);
    }

    /**
      * execute [this] Task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        children.batch( callback );
    }
}
