package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.sys.*;

import pman.async.*;
import pman.tools.mediatags.MediaTagReader;

import gryffin.display.Image;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import edis.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.Asyncs;
using tannus.FunctionTools;

class LoadAlbumArt extends Task1 {
    /* Constructor Function */
    public function new():Void {
        super();

        albumArt = null;
        path = '';
    }

/* === Instance Methods === */

    public function load(path:String, ?done:Cb<Image>):Promise<Image> {
        this.path = path;

        return Promise.create({
            run(function(?error) {
                if (error != null) {
                    throw error;
                }
                else {
                    return albumArt;
                }
            });
        }).toAsync( done );
    }

    public static inline function loadAlbumArt(path:String, ?done:Cb<Image>):Promise<Image> {
        return new LoadAlbumArt().load(path, done);
    }

    /**
      * execute [this] betty
      */
    override function execute(done: VoidCb):Void {
        var mtr = new MediaTagReader( path );
        mtr.setTagsToRead([
            'picture'
        ]);
        mtr.read({
            onError: done.raise(),
            onSuccess: function(tags: TagResults) {
                echo( tags );
                if (tags.tags != null && tags.tags.picture != null) {
                    var pic = tags.tags.picture;
                    var data = new js.html.Uint8ClampedArray( pic.data );
                    var data:js.html.Blob = new js.html.Blob([data.buffer], {
                        type: pic.format
                    });
                    var uri:String = js.html.URL.createObjectURL( data );
                    var img:Image = Image.load(uri, function(img: Image) {
                        albumArt = img;
                        done();
                    });
                }
            }
        });
    }

/* === Instance Fields === */

    public var albumArt: Null<Image>;
    public var path: String;
}
