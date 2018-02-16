package pman.http.domains;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.http.*;

import pman.async.Task1;

import js.html.URL as Url;

import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using pman.bg.URITools;

class YouTubeHandler extends DomainHandler {
    override function getMediaId(?callback:Cb<Dynamic>):Promise<Dynamic> {
        return new Promise<Dynamic>(function(accept, reject) {
            defer(function() {
                var qs:QueryString = QueryString.parse( url.search );
                if (qs.exists('v')) {
                    accept(qs['v'][0]);
                }
                else {
                    accept( null );
                };
            });
        }).toAsync( callback );
    }

    override function getMediaInfo(id:Dynamic, ?callback:Cb<Dynamic>):Promise<Dynamic> {
        return new Promise<Dynamic>(function(accept, reject) {
            var req = new WebRequest();
            req.open('GET', 'http://www.youtube.com/get_video_info?video_id=$id');
            req.loadAsText(function(txt: String) {
                var data:Dynamic = QueryString.parse( txt ).toObject();
                accept( data );
            });
            req.onError(function(event) {
                reject( event );
            });
            req.send();
        });
    }
}
