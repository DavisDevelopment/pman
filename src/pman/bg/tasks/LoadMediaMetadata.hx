package pman.bg.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import ffmpeg.Fluent;

import pman.bg.Dirs;
import pman.bg.media.MediaMetadata;

import Slambda.fn;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;
using ffmpeg.FluentTools;

class LoadMediaMetadata extends Task2<MediaMetadata> {
    /* Constructor Function */
    public function new(path: Path):Void {
        super();

        this.path = path;
        this.meta = new MediaMetadata();
    }

/* === Instance Methods === */

    /**
      * get a Promise for the metadata
      */
    public function getMetadata():Promise<Null<MediaMetadata>> {
        return execute.toPromise();
    }

    /**
      * execute [this] Task
      */
    override function execute(done: Cb<MediaMetadata>):Void {
        Fluent.probe(path.toString(), function(?error, ?info) {
            if (error != null) {
                return done(error, null);
            }
            else {
                // copy over duration
                meta.duration = info.format.duration;

                // copy video data
                if (info.hasVideo()) {
                    var vs = info.videoStreams[0];

                    // copy resolution information
                    meta.video = {
                        width: vs.width,
                        height: vs.height
                    };

                    // copy framerate information
                    meta.video.frame_rate = vs.avg_frame_rate;
                    meta.video.time_base = vs.time_base;
                }

                // copy audio data
                if (info.hasAudio()) {
                    var as = info.audioStreams[0];
                    meta.audio = {
                        channels: as.channels,
                        channel_layout: as.channel_layout
                    };
                }
                
                info = null;
                done(null, meta);
            }
        });
    }

/* === Instance Fields === */

    public var path: Path;
    public var meta: MediaMetadata;

/* === Static Methods === */

    public static inline function load(path: Path):Promise<MediaMetadata> {
        return new LoadMediaMetadata( path ).getMetadata();
    }
}
