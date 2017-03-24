package pman.async;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.node.*;
import tannus.node.Fs as Nfs;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.Tools.now;

import pman.core.*;
import pman.media.*;
import pman.tools.mp4box.MP4Box;

import js.Browser.window;
import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Mp4InfoLoader {
    /* Constructor Function */
    public function new():Void {
        box = new MP4Box();
    }

/* === Instance Methods === */

    /**
      * initiate loading of the metadata on [path]
      */
    public function loadSync(path : Path):MP4Info {
        var bytes:ByteArray = Fs.read( path );
        var buffer:Buffer = bytes.getData();
        sfs(buffer, 0);

        box.appendBuffer( buffer );
        var info = box.getInfo();
        return info;
    }

    /**
      * initiate loading of the metadata
      */
    public function load(path : Path):Promise<MP4Info> {
        return Promise.create({
            var infoParsed:Bool = false;

            // register events
            box.onReady = (function(info : MP4Info) {
                infoParsed = true;

                return info;
            });
            box.onError = (function(error : Dynamic) {
                throw error;
            });

            var fileStart:Int = 0;
            // chunk size (1MB)
            var chunkSize:Int = (1 * 1024 * 1024);

            // prepare chunked read
            function readStep(data : Buffer):Bool {
                sfs(data, fileStart);
                fileStart = box.appendBuffer( data );
                @ignore return !infoParsed;
            }
            function readComplete():Void {
                trace('chunked read has stopped');
            }

            chunkedRead(path, chunkSize, readStep, readComplete);
        });
    }

    /**
      * chunked file-read
      */
    private function chunkedRead(path:Path, chunkSize:Int, step:Buffer->Bool, complete:Void->Void):Void {
        Nfs.open(path.toString(), 'r', function(err, fid:Int) {
            if (err != null) {
                throw err;
            }

            function readNextChunk():Void {
                var buf:Buffer = new Buffer( chunkSize );
                Nfs.read(fid, buf, 0, chunkSize, null, function(err, nread, b) {
                    if (err != null) {
                        throw err;
                    }

                    if (nread == 0) {
                        Nfs.close(fid, function(err) {
                            if (err != null) {
                                throw err;
                            }
                            complete();
                        });
                    }

                    var data:Buffer;
                    if (nread < chunkSize) {
                        data = buf.slice(0, nread);
                    }
                    else {
                        data = buf;
                    }

                    var continu = step( data );
                    if ( continu ) {
                        readNextChunk();
                    }
                    else {
                        Nfs.close(fid, function(err) {
                            if (err != null) {
                                throw err;
                            }
                            complete();
                        });
                    }
                });
            }

            readNextChunk();
        });
    }

    /**
      * when [this] has finished loading
      */
    private function _loaded(info : Dynamic):Void {
        trace( info );
    }

    /**
      * set the magical 'fileStart' property
      */
    private function sfs(buffer:Buffer, fileStart:Int):Void {
        var ab:Dynamic = buffer.buffer;
        ab.fileStart = fileStart;
    }

/* === Instance Fields === */

    private var box : MP4Box;
}
