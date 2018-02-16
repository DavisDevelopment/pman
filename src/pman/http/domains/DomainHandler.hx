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

class DomainHandler {
    /* Constructor Function */
    public function new(name:String, url:Url):Void {
        this.name = name;
        this.url = url;
    }

/* === Instance Methods === */

    /**
      * get [this] domain's media id
      */
    public function getMediaId(?callback: Cb<Dynamic>):Promise<Dynamic> {
        throw 'not implemented';
    }

    public function getMediaInfo(mediaId:Dynamic, ?callback:Cb<Dynamic>):Promise<Dynamic> {
        throw 'not implemented';
    }

/* === Instance Fields === */

    public var name: String;
    public var url: Url;
}
