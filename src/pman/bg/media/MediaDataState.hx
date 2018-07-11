package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaSource;
import pman.bg.media.MediaRow;
import pman.bg.media.Mark;
import pman.bg.db.*;
import pman.bg.tasks.*;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;
import haxe.extern.EitherType as Either;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.DictTools;
using tannus.ds.AnonTools;

class MediaDataState {
    /* Constructor Function */
    public function new(?decl: MediaDataStateDecl) {
        if (decl == null)
            decl = {};
        var betty = decl.deepCopy(untyped this, true);
    }

/* === Instance Methods === */
/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var mediaId: Null<String>;
    public var mediaUri: Null<String>;

    public var views(default, default): Null<Int>;
    public var starred(default, default): Null<Bool>;
    public var rating(default, default): Null<Float>;
    public var contentRating(default, default): Null<String>;
    public var channel(default, default): Null<String>;
    public var description(default, default): Null<String>;
    public var attrs(default, default): Null<Dict<String, Dynamic>>;
    public var marks(default, default): Null<Array<Mark>>;
    public var tags(default, default): Null<Array<String>>;
    public var actors(default, default): Null<Array<Actor>>;

    public var meta(default, default): Null<MediaMetadata>;
}

typedef MediaDataStateDecl = {
    ?mediaId: String,
    ?mediaUri: String,
    ?views: Float,
    ?starred: Bool,
    ?rating: Float,
    ?contentRating: String,
    ?channel: String,
    ?description: String,
    ?attrs: Dict<String, Dynamic>,
    ?marks: Array<Mark>,
    ?actors: Array<Actor>,
    ?tags: Array<Tag>,
    ?meta: Either<MediaMetadata, MediaMetadataDecl>
};

typedef MediaMetadataDecl = {
    ?mimeType: String,
    ?duration: Float,
    ?video: {?width:Int, ?height:Int, ?frame_rate:String, ?time_base:String},
    ?audio: {?channels:Int, ?channel_layout:String}
};
