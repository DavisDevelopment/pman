package pman.http;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.http.*;

import pman.async.Task1;
import pman.http.domains.*;

import js.html.URL as Url;

import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using pman.bg.URITools;

class UrlTransformer extends Task1 {
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * kick off [this] task
      */
    public function transform(inUrl:String, ?callback:Cb<String>):StringPromise {
        return new Promise(function(accept, reject) {
            in_url = url( inUrl );
            out_url = url( inUrl );

            run(function(?error: Dynamic) {
                if (error != null) {
                    reject( error );
                }
                else {
                    trace( out_url );
                    accept(str( out_url ));
                }
            });
        }).toAsync( callback ).string();
    }

    /**
      * execute [this] task
      */
    override function execute(complete: VoidCb):Void {
        trace( in_url );
        switch_domain( complete );
    }
    
    /**
      * hand off url-processing to domain-specific handlers
      */
    private function switch_domain(done: VoidCb):Void {
        switch ( in_url.hostname ) {
            case 'www.youtube.com':
                get_new_url('youtube', YouTubeHandler).then(function(url: Url) {
                    echo( url );
                }).unless(done.raise());

            default:
                done();
        }
    }

    private function get_new_url<T:DomainHandler>(name:String, type:Class<T>, ?url:Url):Promise<Url> {
        return new Promise(function(accept, reject) {
            var d:T = domain(name, type, url);
            d.getMediaId().then(function(id: String) {
                d.getMediaInfo(id, function(?error, ?info:Dynamic) {
                    if (error != null) {
                        reject( error );
                    }
                    else {
                        if (info == null) {
                            reject('no data loaded');
                        }

                        switch ( name ) {
                            case 'youtube':
                                echo( info.url_encoded_fmt_stream_map );

                            default:
                                accept( null );
                        }
                    }
                });
            }, cast reject);
        });
    }

    private function domain<T:DomainHandler>(name:String, type:Class<T>, ?url:Url):T {
        if (url == null)
            url = in_url;
        var res:T = Type.createInstance(type, untyped [name, url]);
        return res;
    }

/* === Static Utilities === */

    private static inline function str2url(s:String, ?base:Url):Url return (base != null ? new Url(s, base) : new Url( s ));
    private static inline function url(s: String, ?base: Url):Url return str2url(s, base);

    private static inline function url2str(url: Url):String return url.href;
    private static inline function str(url: Url):String return url2str( url );

    private static inline function chars(nums: Array<Byte>):String {
        return nums.map(n -> n.aschar).join('');
    }

/* === Instance Fields === */

    public var in_url: Url;
    public var out_url: Url;
}
