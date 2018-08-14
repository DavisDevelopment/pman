package pman.media;

import tannus.io.*;
import tannus.ds.Lazy;
import tannus.ds.Ref;
import tannus.ds.Pair;
import tannus.ds.Dict;
import tannus.ds.Maybe;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.async.VoidPromise;
import tannus.async.Promise;
import tannus.async.promises.*;
import tannus.async.Future;
import tannus.async.Result;
import tannus.async.Feed;
import tannus.stream.Stream;

import pman.Errors;
import pman.core.Player;
import pman.core.MediaResolutionContext;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaType;
import pman.bg.media.MediaFeature;
import pman.media.Media as MediaItem;
import pman.media.MediaProvider;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.ds.Option;
import haxe.extern.EitherType;

import Slambda.fn;
import pman.Errors.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.MapTools;
using tannus.ds.DictTools;
using pman.media.MediaTools;
using pman.bg.DictTools;
using pman.bg.URITools;
using tannus.async.Asyncs;
using tannus.FunctionTools;

/**
  represents a dynamically-defined partial implementation of a MediaProvider instance
 **/
@:expose('MediaProviderDefinition')
class MediaProviderDefinition {
    /* Constructor Function */
    public function new(info:MpInfo, builder:MediaItemBuilder<MediaItem>):Void {
        this.baseInfo = info;
        this.info = baseInfo.copy();
        this.mediaItemBuilder = builder;
        this.middlewares = new Array();
    }

/* === Methods === */

    /**
      convert [this] into a MediaProvider
     **/
    public function getMediaProvider():MediaProvider {
        applyMiddlewares();
        return new DefinedMediaProvider( this );
    }

    /**
      compute [info]
     **/
    public function getFinalInfo():MpInfo {
        var result:MpInfo = baseInfo.copy(),
        step: MediaProviderMiddlewareStep;

        for (middle in middlewares) {
            step = middle.apply( result );
            switch step {
                case Resume:
                    continue;

                case Reset:
                    result = baseInfo.copy();
                    continue;

                case Replace(newState):
                    result = newState;
                    continue;

                case Exception(error):
                    throw error;

                case _:
                    continue;
            }
        }

        return result;
    }

    /**
      apply middleware to [info]
     **/
    public function applyMiddlewares() {
        this.info = getFinalInfo();
    }

    /**
      obtain a Promise for a MediaItem instance
     **/
    public function getMediaItem(?i: MpInfo):Promise<MediaItem> {
        return mediaItemBuilder.getMediaItem(i != null ? i : info);
    }

    /**
      add a Middleware to [this]
     **/
    public inline function addMiddleware(m: MediaProviderMiddleware) {
        middlewares.push( m );
    }

    /**
      add multiple Middlewares
     **/
    public function addMiddlewares(mi: Iterable<MediaProviderMiddleware>) {
        for (m in mi) {
            addMiddleware( m );
        }
    }

/* === Properties === */

    /**
      object used to build the MediaItem for [this]
     **/
    public var mediaItemBuilder(get, set): MediaItemBuilder<MediaItem>;
    private inline function get_mediaItemBuilder():MediaItemBuilder<MediaItem> {
        return _mediaItemBuilder.get();
    }
    private function set_mediaItemBuilder(v: MediaItemBuilder<MediaItem>):MediaItemBuilder<MediaItem> {
        _mediaItemBuilder.set( v );
        return get_mediaItemBuilder();
    }

/* === Variables === */

    /* the basic info for the MediaItem that [this] represents */
    public var info(default, null): MpInfo;

    /* list of middleware objects for [this] */
    public var middlewares(default, null): Array<MediaProviderMiddleware>;

    /* the state of [info] as it is upon initialization of [this] */
    var baseInfo(default, null): MpInfo;

    /* Ref<_> for the MediaItemBuilder for [this] */
    private var _mediaItemBuilder(default, null): Ref<MediaItemBuilder<MediaItem>>;
}

class DefinedMediaProvider extends MediaProvider {
    /* Constructor Function */
    public function new(mpdef: MediaProviderDefinition) {
        super();

        this.definition = mpdef;
        this.info = definition.info.copy();

        this.src = definition.info.src;
        this.type = definition.info.type;
        var ifeats = definition.info.features;
        for (feat in ifeats.keys()) {
            features[feat] = ifeats[feat];
        }
    }

/* === Methods === */

    override function getMedia():Promise<MediaItem> {
        return definition.getMediaItem( info );
    }

/* === Variables === */

    public var definition: MediaProviderDefinition;
    var info: MpInfo;
}

/**
  basemost information that will be required by a MediaProviderDefinition
 **/
class MpInfo {
    /* Constructor Function */
    public function new(?src:MediaSource, ?type:MediaType, ?features:Map<MediaFeature, Bool>, _mkrefs:Bool=true):Void {
        if ( _mkrefs ) {
            /*[= default values =]*/
            _src = Ref.const(null);
            _type = Ref.const(MTUnknown);
            _features = [for (feature in MediaFeature.createAll()) feature => false];

            if (src != null) {
                this.src = src;
            }

            if (type != null) {
                this.type = type;
            }

            if (features != null) {
                this.features = features;
            }
        }
    }

/* === Methods === */

    /**
      create and return a deep-copy of [this] that references the same information
     **/
    public inline function clone():MpInfo {
        var copy = fromRefs(_src, _type);
        copy._features = _features;
        return copy;
    }

    /**
      create and return a shallow-copy of [this] that contains the same data, but is unlinked from [this] data
     **/
    public inline function copy():MpInfo {
        return new MpInfo(src, type, features.copy());
    }

/* === Static Methods === */

    /**
      construct and return a new MpInfo instance from the given References
     **/
    public inline static function fromRefs(src:Ref<Null<MediaSource>>, type:Ref<MediaType>):MpInfo {
        var i = new MpInfo(null, null, null, false);
        i._src = src;
        i._type = type;
        return i;
    }

/* === Properties === */

    /**
      the MediaSource, or the 'source' from which the given Media is being provided
     **/
    public var src(get, set): Null<MediaSource>;
    inline function get_src() return _src.get();
    function set_src(nv: Null<MediaSource>) {
        _src.set( nv );
        return get_src();
    }

    /**
      the MediaType to be provided
     **/
    public var type(get, set): Null<MediaType>;
    inline function get_type() return _type.get();
    function set_type(nv: Null<MediaType>) {
        if (nv == null)
            nv = MTUnknown;
        _type.set( nv );
        return get_type();
    }

    /**
      MediaFeature values, mapped to a Boolean representing whether the relevant MediaItem has the given feature
     **/
    public var features(get, set): Map<MediaFeature, Bool>;
    inline function get_features() return _features;
    function set_features(nv: Map<MediaFeature, Bool>) {
        for (fe in nv.keys()) {
            _features[fe] = nv[fe];
        }
        return get_features();
    }

/* === Variables === */

    // reference to MediaSource
    public var _src: Ref<Null<MediaSource>>;

    // reference to MediaType
    public var _type: Ref<Null<MediaType>>;

    // feature map
    public var _features: Map<MediaFeature, Bool>;
}

class LazyMediaItemBuilder<T:MediaItem> extends MediaItemBuilderBase<T> {
    /* Constructor Function */
    public function new(item:Lazy<Promise<T>>) {
        this.item = item;
    }

    override function getMediaItem(info: MpInfo):Promise<T> {
        return item.get();
    }

    var item: Lazy<Promise<T>>;
}

class FlatMediaItemBuilder<T:MediaItem> extends MediaItemBuilderBase<T> {
    /* Constructor Function */
    public function new(builder: Promise<MediaItemBuilder<T>>) {
        this.promise = builder;
    }

    override function getMediaItem(info: MpInfo):Promise<T> {
        return promise.flatMap(function(builder):Promise<T> {
            return builder.getMediaItem( info );
        });
    }

    var promise: Promise<MediaItemBuilder<T>>;
}

class FunctionalMediaItemBuilder<T:MediaItem> extends MediaItemBuilderBase<T> {
    /* Constructor Function */
    public function new(f: Void->Promise<T>) {
        this.builder = f;
        this.promise = null;
        this.item = null;
    }

    override function getMediaItem(info: MpInfo):Promise<T> {
        if (item != null) {
            return cast Promise.resolve( item );
        }
        else if (promise != null) {
            return cast promise.transform( FunctionTools.identity );
        }
        else {
            promise = builder();
            promise.unless(function(error) {
                this.promise = null;
                this.item = null;
            });
            promise.then(function(mediaItem: T) {
                this.promise = null;
                this.item = mediaItem;
            });
            return promise;
        }
    }

    var builder: Void->Promise<T>;
    var promise: Null<Promise<T>>;
    var item: Null<T>;
}

class FwdMediaItemBuilder<T:MediaItem> extends MediaItemBuilderBase<T> {
    /* Constructor Function */
    public function new(builder: Lazy<MediaItemBuilder<T>>) {
        this.builder = builder;
    }

    override function getMediaItem(info: MpInfo):Promise<T> {
        return builder.get().getMediaItem( info );
    }

    var builder: Lazy<MediaItemBuilder<T>>;
}

class MediaItemBuilderBase<T:MediaItem> implements MpDefMediaItemManager<T> {
    public function getMediaItem(info: MpInfo):Promise<T> {
        ni();
    }
}

class MpMiddleBase implements MediaProviderMiddlewareModel {
    public function apply(info: MpInfo):MediaProviderMiddlewareStep {
        return Resume;
    }
}

class FunctionalMpMiddle extends MpMiddleBase {
    /* Constructor Function */
    public function new(f) {
        this.f = f;
    }

    override function apply(info: MpInfo):MediaProviderMiddlewareStep {
        return f( info );
    }

    var f: MpInfo -> MediaProviderMiddlewareStep;
}

class EmptyMpMiddle extends MpMiddleBase {
    public function new() {  }

    static var inst:EmptyMpMiddle = new EmptyMpMiddle();

    public static inline function make():EmptyMpMiddle {
        return inst;
    }
}

/**
  manages the creation of MediaItems
 **/
interface MpDefMediaItemManager <Item : MediaItem> {
    /**
      build and return a Promise of a MediaItem
     **/
    function getMediaItem(info: MpInfo): Promise<Item>;
}

interface MediaProviderMiddlewareModel {
    function apply(mpd: MpInfo):MediaProviderMiddlewareStep;
}

/**
  represents a 'step' in the middleware application process
 **/
enum MediaProviderMiddlewareStep {
    /* continue applying middleware */
    Resume;

    /* reset state to starting value and continue */
    Reset;

    /* reset info to its state as it was before starting to apply [this] middleware */
    //Rollback;

    /* reassign the state to [info] */
    Replace(info: MpInfo);

    /* also apply [tail] middleware before continuing */
    Tail(tail: MediaProviderMiddleware);

    /* an exception was thrown while applying [this] middleware */
    Exception(e: Dynamic);
}

@:forward
abstract MediaItemBuilder <T : MediaItem> (MpDefMediaItemManager<T>) from MpDefMediaItemManager<T> to MpDefMediaItemManager<T> {
/* === Factory Methods === */

    @:from
    public static function lazy<T:MediaItem>(l: Lazy<Promise<T>>):MediaItemBuilder<T> {
        return new LazyMediaItemBuilder( l );
    }

    public static function fwd<T:MediaItem>(mib: MediaItemBuilder<T>):MediaItemBuilder<T> {
        return new FwdMediaItemBuilder( mib );
    }

    @:from
    public static function make<T:MediaItem>(f: Void->Promise<T>):MediaItemBuilder<T> {
        return new FunctionalMediaItemBuilder( f );
    }

    @:from
    public static function flatten<T:MediaItem>(prom: Promise<MediaItemBuilder<T>>):MediaItemBuilder<T> {
        return new FlatMediaItemBuilder( prom );
    }
}

@:forward
abstract MediaProviderMiddleware (MediaProviderMiddlewareModel) from MediaProviderMiddlewareModel to MediaProviderMiddlewareModel {
/* === Factory Methods === */

    public static inline function empty():MediaProviderMiddleware {
        return EmptyMpMiddle.make();
    }

    @:from
    public static inline function make(f: MpInfo->MediaProviderMiddlewareStep):MediaProviderMiddleware {
        return new FunctionalMpMiddle( f );
    }

    @:from
    public static function makeVoid(f: MpInfo->Void):MediaProviderMiddleware {
        return make(function(info: MpInfo):MediaProviderMiddlewareStep {
            try {
                f( info );
                return Resume;
            }
            catch (err: Dynamic) {
                return Exception( err );
            }
        });
    }

    @:from
    public static function makeInfoArgs(f: Ref<MediaSource>->Ref<MediaType>->Map<MediaFeature, Bool>->MediaProviderMiddlewareStep):MediaProviderMiddleware {
        return make(function(info) {
            return f(info._src, info._type, info._features);
        });
    }

    @:from
    public static function makeVoidInfoArgs(f: Ref<MediaSource>->Ref<MediaType>->Map<MediaFeature, Bool>->Void):MediaProviderMiddleware {
        return make(function(info: MpInfo):MediaProviderMiddlewareStep {
            try {
                f(info._src, info._type, info._features);
                return Resume;
            }
            catch (err: Dynamic) {
                return Exception( err );
            }
        });
    }
}
