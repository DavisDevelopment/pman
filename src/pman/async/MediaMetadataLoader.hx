package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.node.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;

import Std.*;
import tannus.math.TMath.*;
import js.Browser.window;
import electron.Tools.defer;
import gryffin.Tools.now;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaMetadataLoader extends StandardTask<String, MediaMetadata> {
    /* Constructor Function */
    public function new(path : Path):Void {
        super();

        this.path = path;
        this.meta = new MediaMetadata();
    }
   
/* === Instance Methods === */

    public function getMetadata():Promise<MediaMetadata> {
        return Promise.create({
            perform(function() {
                return meta;
            });
        });
    }

/* === Computed Instance Fields === */

    public var meta(get, set):MediaMetadata;
    private inline function get_meta() return result;
    private inline function set_meta(v) return (result = v);

/* === Instance Fields === */

    public var path : Path;
}
