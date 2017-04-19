package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.node.Fs;

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

class CatJsLibs extends Concatenate {
    public function new(o : TaskOptions):Void {
        super(path('scripts/all-libs.js'));

        compress = (o.compress || o.scripts.compress);

        var names = ['jquery.min.js', 'jquery-ui.min.js', 'foundation.min.js', 'otherstuff.js'];
        var scripts = names.map.fn(path( 'scripts/$_' ));
        for (script in scripts) {
            addSource( script );
        }
    }

    /**
      * place results in file
      */
    override function putResult(data:ByteArray, callback:?Dynamic->Void):Void {
        var code:String = data.toString();
        var header:String = "if (typeof module === 'object') {\nwindow.module = module;\nmodule=undefined;\n}\n(function(){\n";
        var footer:String = "\n}());\nif(window.module){\nmodule=window.module;\n}";
        code = (header + code + footer);
        data = ByteArray.ofString( code );
        super.putResult(data, function(?error:Dynamic) {
            if ( compress ) {
                var compress = new CompressJs( dest );
                compress.run( callback );
            }
            else {
                callback( error );
            }
        });
    }

    private var compress:Bool;
}
