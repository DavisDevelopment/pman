package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.MediaRow;
import pman.bg.media.MediaSource;

import Slambda.fn;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;

typedef MediaDataDelta = {
    ?views: Delta<Int>,
    ?starred: Delta<Bool>,
    ?rating: Delta<Float>,
    ?contentRating: Delta<String>,
    ?channel: Delta<String>,
    ?description: Delta<String>,
    //?marks: ArrayDelta<Mark, Delta<Mark>>,
    ?marks: Delta<Array<Mark>>,
    ?tags: ArrayDelta<Tag, Delta<Tag>>,
    ?actors: ArrayDelta<Actor, Delta<Actor>>,
    ?attrs: DictDelta,
    ?meta: Delta<MediaMetadata>
};

typedef MediaRowDelta = {
    ?title: Delta<String>,
    ?uri: Delta<String>,
    ?data: MediaDataRowDelta
};

typedef MediaDataRowDelta = {
    ?views: Delta<Int>,
    ?starred: Delta<Bool>,
    ?rating: Delta<Float>,
    ?contentRating: Delta<String>,
    ?channel: Delta<String>,
    ?description: Delta<String>,
    //?marks: ArrayDelta<Dynamic, Delta<Dynamic>>,
    ?marks: Delta<Array<Dynamic>>,
    ?tags: ArrayDelta<String, Delta<String>>,
    ?actors: ArrayDelta<String, Delta<String>>,
    ?attrs: DictDelta,
    ?meta: Delta<MediaMetadataRow>
};

typedef DictDelta = Array<DictDeltaItem>;

enum DictDeltaItem {
    DdiAdd(key:String, value:Dynamic);
    DdiRemove(key: String);
    DdiAlter(key:String, value:Delta<Dynamic>);
}

typedef ArrayDelta<TItem, TDelta> = {
    items: Array<ArrayDeltaItem<TItem, TDelta>>,
    src: Array<TItem>
};

enum ArrayDeltaItem<TItem, TDelta> {
    AdiAlter(item:TItem, delta:TDelta);
    AdiAppend(item: TItem);
    AdiRemove(item: TItem);
    AdiInsert(item:TItem, index:Int);
}
