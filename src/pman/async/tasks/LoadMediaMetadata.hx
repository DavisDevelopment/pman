package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.node.*;
import tannus.node.Fs as Nfs;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.Tools.now;

import pman.core.*;
import pman.media.*;
import pman.async.*;
//import pman.tools.mp4box.MP4Box;
//import pman.tools.mp4box.MP4Metadata;

import ffmpeg.FFfmpeg;
import ffmpeg.Fluent;

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
using pman.async.VoidAsyncs;
using pman.async.Asyncs;

class LoadMediaMetadata extends Task2<MediaMetadata> {
    private var path : Path;
    public var meta : MediaMetadata;

    /* Constructor Function */
    public function new(path : Path):Void {
        super();

        this.path = path;
        this.meta = new MediaMetadata();
    }

    /**
      * get a Promise for the metadata
      */
    public function getMetadata():Promise<Null<MediaMetadata>> {
        return execute.toPromise();
    }

    /**
      * execute [this] task
      */
    override function execute(done : Cb<MediaMetadata>):Void {
        Fluent.probe(path.toString(), function(?error, ?info) {
            if (error != null) {
                return done(error, null);
            }
            else {
                meta.duration = info.format.duration;
                if (info.hasVideo()) {
                    var vs = info.videoStreams[0];
                    meta.video = {
                        width: vs.width,
                        height: vs.height
                    };
                }
                /*
                if (info.hasAudio()) {
                    var as = info.audioStreams[0];
                    meta.audio = {
                        channels: as.channels,
                        channel_layout: as.channel_layout
                    };
                }
                */
                info = null;
                done(null, meta);
            }
        });
    }
}
