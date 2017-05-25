package pack.adt;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

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

class Common extends AppDirTransformer {
    override function prune(done : Void->Void):Void {
        var del:Array<Path> = new Array();
        var styles = new Directory(sub('styles'));
        var scripts = new Directory(sub('scripts'));

        if ( go.compress ) {
            var names = Fs.readDirectory( styles.path );
            names.remove('pman.css');
            names.remove('scaffolds.css');
            for (n in names)
                del.push(sub('styles/$n'));
            names = Fs.readDirectory( scripts.path );
            names.remove('background.min.js');
            names.remove('all-libs.min.js');
            names.remove('content.min.js');
            for (n in names)
                del.push(sub('scripts/$n'));
            if ( go.compress )
                del.push(sub('pages/index.html'));
            else
                del.push(sub('pages/index.min.html'));
        }
        else {

        }
        
        //if (ps.platform != 'win32') {
            //del.push(sub('assets/ffmpeg-static/ffmpeg.exe'));
            //del.push(sub('assets/ffmpeg-static/ffprobe.exe'));
        //}

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
        if ( go.compress ) {
            meta['main'] = 'scripts/background.min.js';
        }
        else {
            meta['main'] = 'scripts/background.js';
        }

        defer(callback.bind(null, meta));
    }
}
