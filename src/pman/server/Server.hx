package pman.server;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.sys.FileSystem in Fs;
import tannus.node.*;
import tannus.node.Fs as Nfs;

import electron.Tools.defer;

import tannus.TSys as Sys;

import pman.db.AppDir;
import pman.async.*;

import js.Lib.require;
import haxe.Template;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.server.ServerTools;

class Server {
    /* Constructor Function */
    public function new(main : Background):Void {
        this.main = main;
        _cc = new Map();
        _routes = new Map();
    }

/* === Instance Methods === */

    /**
      * initialize [this] server
      */
    public function init(?data : ServerInitData):Void {
        this.data = data;

        app = express();
        app.get('/watch/:uuid', sendSeekable, _respond.bind());

        _server = app.listen( 6969 );
    }

    public function close():Void {
        _server.close();
    }

    public function serve(path : Path):String {
        for (uid in _routes.keys()) {
            if (_routes[uid].str == path.str)
                return uid;
        }
        var id = Uuid.create();
        _routes[id] = path;
        return id;
    }

    /**
      * express route handler
      */
    private function _respond(req:Dynamic, res:Dynamic, next:Dynamic):Void {
        var uid:Null<String> = req.params.uuid;
        if (uid != null && uid.trim().empty()) uid = null;
        if (uid != null) {
            if (_routes.exists( uid )) {
                var c = _ctx( uid );
                res.sendSeekable(c.stream, {
                    length: c.size
                });
            }
            else {
                res.status( 404 ).end();
            }
        }
        else {
            res.write('<body>');
            for (id in _routes.keys()) {
                var href = './$id';
                res.write('<a href="$href">$id</a>');
                res.write('</br>');
            }
            res.write('</body>');
        }
    }

    private function _ctx(uid:String):Ctx {
        if (!_cc.exists( uid )) {
            var path:Path = _routes.get( uid );
            var context:Ctx = {
                path: path,
                size: _size( path ),
                stream: _stream( path )
            };
            return (_cc[uid] = context);
        }
        else {
            return _cc[uid];
        }
    }

    private function _size(path:Path):Int {
        return Fs.stat(path.toString()).size;
    }
    private function _stream(path : Path):ReadableStream {
        return Nfs.createReadStream(path.toString());
    }

/* === Instance Fields === */

    public var main : Background;
    public var data : ServerInitData;
    public var _routes : Map<String, Path>;
    public var _cc : Map<String, Ctx>;

    private var app : Dynamic;
    private var _server : Dynamic;

/* === Static Fields === */

    private static var express:Dynamic = {require('express');};
    private static var sendSeekable:Dynamic = {require('send-seekable');};
}

typedef Ctx = {
    path: Path,
    size: Int,
    stream: ReadableStream
};
