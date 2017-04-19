package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class CompileStyles extends Task {
    /* Constructor Function */
    public function new(o : TaskOptions):Void {
        super();

        input = path('styles/pman.less');
        output = path('styles/pman.css');
        checks = [
            'styles/pman.less',
            'styles/theme.less',
            'styles/utils.less',
            'styles/widgets.less',
            'styles/widgets/dialogs.less',
            'styles/widgets/playlist.less'
        ].map.fn(path(_));
    }

/* === Instance Methods === */

    /**
      * execute [this] task
      */
    override function execute(callback : ?Dynamic->Void):Void {
        if (shouldCompile()) {
            var comp = new CompileLess(input, output);
            comp.run( callback );
        }
        else {
            defer(function() callback());
        }
    }

    /**
      * determine whether it is even necessary to compile
      */
    private function shouldCompile():Bool {
        return checks.anyNewerThan( output );
    }

    private var input:Path;
    private var output:Path;
    private var checks:Array<Path>;
}
