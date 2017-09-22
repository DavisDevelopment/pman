package pman.display;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import pman.core.*;
import pman.media.Playlist;
import pman.Globals.*;
import pman.edb.*;
import pman.edb.AppDirPlaylists;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Template;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Templates {
/* === Methods === */

    /**
      * get a Template by name
      */
    public static function get(name : String):Maybe<Template> {
        if (!name.endsWith('.html')) {
            name += '.html';
        }
        _ensure();
        if (tcache.exists( name )) {
            return tcache[name];
        }
        else {
            if (tfcache.exists( name )) {
                return (tcache[name] = new Template(tfcache[name]));
            }
            else {
                return null;
            }
        }
    }

    /**
      * ensure that all data is ready to be worked with
      */
    private static function _ensure():Void {
        if (tfcache == null) {
            tfcache = new Dict();
            var tdp = appDir.templatesPath();
            if (Fs.exists( tdp )) {
                var names = Fs.readDirectory( tdp );
                for (name in names) {
                    tfcache[name] = Std.string(Fs.read(tdp.plusString(name).normalize()));
                }
            }
            else {
                throw 'Error: Template folder "$tdp" does not exist';
            }
        }
        if (tcache == null) {
            tcache = new Dict();
        }
    }

/* === Fields === */
    private static var tfcache:Dict<String, String>;
    private static var tcache:Dict<String, Template>;
}
