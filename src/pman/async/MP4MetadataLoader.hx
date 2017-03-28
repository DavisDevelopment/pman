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

class MP4MetadataLoader extends MediaMetadataLoader {
    override function action(done : Void->Void):Void {
        var il = new Mp4InfoLoader();
        var ip = il.load( path );
        ip.then(function(info) {
            // general data
            meta.duration = info.nduration;

            // video/audio specific data
            var vt = info.videoTracks[0];
            if (vt != null) {
                if (vt.video != null) {
                    meta.video = {
                        width: vt.video.width,
                        height: vt.video.height
                    };
                }
            }

            var at = info.audioTracks[0];
            if (at != null && at.audio != null) {
                meta.audio = {};
            }

            done();
        });
        ip.unless(function(error) {
            throw error;
        });
    }
}
