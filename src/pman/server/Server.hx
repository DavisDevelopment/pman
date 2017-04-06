package pman.server;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.sys.FileSystem in Fs;
import tannus.node.Fs as NodeFs;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.ext.App;
import electron.Tools.defer;

import js.html.Window;

import tannus.TSys as Sys;

import pman.db.AppDir;

import hxpress.*;
import hxpress.Server as NServer;

import haxe.Template;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.server.ServerTools;

class Server extends NServer {
    /* Constructor Function */
    public function new(main : ServerMain):Void {
        super();

        this.main = main;
    }

/* === Instance Methods === */

    public function init(data : ServerInitData):Void {
        this.data = data;

        route('*', function(req, res) {
            res.headers['server'] = 'pman-server';
        });

        var homeTemplate = readTemplate( 'home.html' );
        route('/home', function(req, res) {
            res.headers['Content-Type'] = 'text/html';
            res.status = 200;
            res.write(homeTemplate.execute({}));            
            res.send();
        });

        var defaultLength:Int = 24325518;
        route('/media.mp4', function(req, res) {
            var r = res.getRaw();
            var mediaPath:Path = new Path('/home/ryan/Videos/Popcorn/porn/asian-hotties/asian-teen-rough-fuck-double-creampie.mp4');
            var mediaStat = Fs.stat( mediaPath );
            var byteRange:Null<IRange> = range( req );

            if (byteRange == null) {
                byteRange = [0, (mediaStat.size - 1)];
            }

            if (byteRange.x == null)
                byteRange.x = 0;
            if (byteRange.y == null)
                byteRange.y = (mediaStat.size - 1);

            r.writeHead(206, {
                'Content-Type': 'video/mp4',
                'Accept-Ranges': 'bytes',
                'Content-Length': Std.string( mediaStat.size ),
                'Content-Range': ('bytes ${byteRange.x}-${byteRange.y}/${mediaStat.size}')
            });

            var stream = NodeFs.createReadStream(mediaPath.toString(), {
                start: byteRange.x,
                end: byteRange.y
            });
            stream.onOpen(function() {
                stream.pipe( r );
            });
            stream.onError(function( error ) {
                r.end(Std.string( error ));
            });
        });

        listen( 6969 );
    }

    /**
      * extract the content range from the given request
      */
    private function range(req : Request):Null<IRange> {
        if (req.headers.exists('range')) {
            var s = req.headers['range'];
            s = s.after('bytes=');
            var vals = s.split('-').map( Std.parseInt );
            return new IRange( vals );
        }
        else {
            return null;
        }
    }

    /**
      * stream the given File onto the given response
      */
    private function stream(path:Path, response:Response, done:Void->Void):Void {
        function step(chunk : ByteArray):Bool {
            response.write( chunk );
            return true;
        }
        function reject( error ) {
            throw error;
        }
        path.chunkedRead(1024, step, done, reject);
    }

    /**
      * read a template
      */
    public function readTemplate(name : String):Template {
        var path = new Path( data.appPath ).plusString('assets/templates/$name');
        var tmplText = Fs.read(path.toString());
        return new Template( tmplText );
    }

/* === Instance Fields === */

    public var main : ServerMain;
    public var data : ServerInitData;
}

abstract IRange (Array<Int>) from Array<Int> {
    public inline function new(a : Array<Int>) {
        this = a;
    }

    public var x(get, set):Null<Int>;
    private inline function get_x() return this[0];
    private inline function set_x(v) return (this[0] = v);

    public var y(get, set):Null<Int>;
    private inline function get_y() return this[1];
    private inline function set_y(v) return (this[1] = v);
}
