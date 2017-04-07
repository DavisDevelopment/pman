package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.math.Random;

import haxe.Serializer;
import haxe.Unserializer;

import pman.core.*;
import pman.media.PlaylistChange;
import pman.media.MediaSource;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

@:forward
abstract MediaSourceList (Array<MediaSource>) from Array<MediaSource> to Array<MediaSource> {
    /* Constructor Function */
    public inline function new(?a : Array<MediaSource>):Void {
        this = (a != null ? a : []);
    }

/* === Methods === */

    public function toStrings():Array<String> {
        return this.map.fn(_.mediaSourceToUri());
    }

/* === Instance Fields === */

}
