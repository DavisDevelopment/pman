package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.bg.media.*;

import Xml;
import Xml.XmlType;
import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.bg.URITools;
using pman.bg.PathTools;

class Data {
    public function new():Void {
        tracks = new Array();
    }

    public function addAttribution(location: String) {
        if (location.hasContent()) {
            (attribution!=null?attribution:attribution=[]).push(location.trim());
        }
    }

    public function addLink(rel:String, uri:String) {
        if (links == null) links = [];
        if (rel.hasContent() && uri.hasContent()) {
            links.push({rel:rel, uri:uri});
        }
    }

    public function addExtension(application:String, node:Xml):Void {
        if (extensions == null) extensions = [];
        if (application.hasContent() && node != null) {
            extensions.push({application:application, node:node});
        }
    }

    public function createTrack(title:String=''):DataTrack {
        return {
            title: title,
            locations: []
        };
    }

    public function addTrack(track: DataTrack) {
        if (track.locations.hasContent() && !tracks.has( track )) {
            tracks.push( track );
        }
    }

    public var title: Null<String>;
    public var creator: Null<String>;
    public var annotation: Null<String>;
    public var info: Null<String>;
    public var location: Null<String>;
    public var image: Null<String>;
    public var date: Null<Date>;
    public var license: Null<String>;
    public var attribution: Null<Array<String>>;
    public var links: Null<Array<Link>>;
    public var extensions: Null<Array<Extension>>;
    public var tracks: Array<DataTrack>;
}

typedef Extension = {
    application: String,
    node: Xml
};
typedef Link = {uri:String, rel:String};

@:structInit
class DataTrack {
    public var locations: Array<String>;
    public var title: String;
    @:optional public var creator: String;
    @:optional public var annotation: String;
    @:optional public var info: String;
    @:optional public var image: String;
    @:optional public var album: String;
    @:optional public var trackNum: Int;
    // in milliseconds
    @:optional public var duration: Int;
    @:optional public var extensions: Array<Extension>;

    public function addExtension(application:String, node:Xml) {
        if (application.hasContent() && node != null) {
            if (extensions == null) extensions = [];
            extensions.push({
                application: application,
                node: node
            });
        }
    }

    public function addLocation(uri: String) {
        if (uri.isUri()) {
            locations.push( uri );
        }
    }
}

typedef TDataTrack = {
    locations: Array<String>,
    title: String,
    ?creator: String,
    ?annotation: String,
    ?info: String,
    ?image: String,
    ?album: String,
    ?trackNum: Int,
    // in milliseconds
    ?duration: Int,
    ?extensions: Array<Extension>
};
