package pack.adt;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;
import Packer.TaskOptions;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class Common extends AppDirTransformer {
    override function prune(done : Void->Void):Void {
        var del:Array<Path> = new Array();
        var styles = new Directory(sub('styles'));
        var scripts = new Directory(sub('scripts'));

        var names = Fs.readDirectory( styles.path );//.without(['pman.css', 'scaffolds.css']));
        names.remove('pman.css');
        names.remove('scaffolds.css');
        for (n in names)
            del.push(sub('styles/$n'));
        names = Fs.readDirectory( scripts.path );//.without(['background.min.js','all-libs.min.js','content.min.js']));
        names.remove('background.min.js');
        names.remove('all-libs.min.js');
        names.remove('content.min.js');
        for (n in names)
            del.push(sub('scripts/$n'));
        del.push(sub('pages/index.html'));

        trace('deleting unnecessary files..');
        for (p in del) {
            trace('deleting $p..');
            if (Fs.isDirectory( p )) {
                Fs.deleteDirectory( p );
            }
            else {
                Fs.deleteFile( p );
            }
        }
        defer( done );
    }

    override function transformMeta(meta:Object, callback:Null<Dynamic>->Object->Void):Void {
        meta['name'] = 'pman';
        meta['main'] = 'scripts/background.min.js';

        defer(callback.bind(null, meta));
    }
}
