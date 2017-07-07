package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import gryffin.display.*;

import haxe.extern.EitherType;

import pman.async.*;
import pman.db.Snapshots;

import pman.Globals.*;
import tannus.math.TMath.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class Snapshot {
    /* Constructor Function */
    public function new(path : Path):Void {
        this.path = path;
        this.id = new SnapName( path.name );
    }

/* === Instance Methods === */

    /**
      * convert to an Image
      */
    public function getImage(done : Cb<Image>):Image {
        var img = Image.load( uri );
        var rede = @:privateAccess img.ready;
        rede.once(function() {
            defer(function() {
                rede.once(function() {
                    done(null, img);
                });
            });
        });
        return img;
    }

    /**
      * delete the file associated with [this]
      */
    public function deleteFile():Void {
        Fs.deleteFile( path );
    }

/* === Computed Instance Fields === */

    public var title(get, never):String;
    private inline function get_title() return id.title;

    public var time(get, never):Float;
    private inline function get_time() return id.time;

    public var uri(get, never):String;
    private inline function get_uri() return ('file://'+path.toString());

/* === Instance Fields === */

    public var path : Path;
    public var id : SnapName;
}
