package pman.tools.mp4box;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.media.Duration;

import pman.tools.mp4box.MP4Box;

@:forward
abstract MP4Metadata (MP4Info) from MP4Info to MP4Info {
    /* Constructor Function */
    public function new(info : MP4Info):Void {
        this = info;
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var raw(get, never):MP4Info;
    private inline function get_raw():MP4Info return this;

    public var nduration(get, never):Float;
    private inline function get_nduration():Float return (this.duration / this.timescale);

    public var duration(get, never):Duration;
    private function get_duration():Duration return Duration.fromFloat( nduration );
}
