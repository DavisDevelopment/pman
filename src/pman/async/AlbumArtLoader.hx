package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.node.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.Tools.now;

import pman.core.*;
import pman.media.*;
import pman.tools.mediatags.MediaTagReader;

import js.Browser.window;
import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class AlbumArtLoader extends StandardTask<String, Image> {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * initiate loading
      */
    public function loadAlbumArt(track:Track):Promise<Null<Image>> {
        this.track = track;
        return Promise.create({
            perform(function() {
                return image;
            });
        });
    }

    /**
      * perform the task itself
      */
    override function action(done : Void->Void):Void {
        var src = getTagReaderSource();
        var reader = new MediaTagReader( src );
        reader.setTagsToRead(['picture']);
        var rp = reader.pread();
        rp.then(function( info ) {
            var picTag = info.tags.picture;
            if (picTag != null && picTag.data != null && picTag.data.length > 0) {
                var bytes:ByteArray = ByteArray.ofData(Buffer.from( picTag.data ));
                var dataUri:String = bytes.toDataUrl( picTag.format );
                Image.load(dataUri, function(img : Image) {
                    image = img;
                    this.result = image;
                    done();
                });
            }
            else {
                done();
            }
        });
        rp.unless(function( error ) {
            done();
        });
    }

    private function getTagReaderSource():String {
        var src : String;
        switch ( track.source ) {
            case MediaSource.MSLocalPath(_.str => path): 
                src = path;
                                                       //case MediaSource.MSUrl(
            default: 
                src = track.uri;
        }
        return src;
    }

/* === Instance Fields === */

    private var track:Track;
    private var image:Null<Image> = null;
}
