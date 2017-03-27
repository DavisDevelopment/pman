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
import pman.tools.mp3duration.MP3Duration;

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

class MP3MetadataLoader extends MediaMetadataLoader {
    override function action(done : Void->Void):Void {
        MP3Duration.duration(path.toString(), function(error, duration) {
            meta.duration = duration;

            meta.audio = {};

            defer( done );
        });
    }
}
