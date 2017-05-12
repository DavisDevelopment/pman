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
import pman.tools.mp4box.MP4Metadata;

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
    public function loadSync(path : Path):MP4Metadata {
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
    public function load(path : Path):Promise<MP4Metadata> {
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

            // handle chunked-read errors
            function readReject(error : Dynamic):Void {
                throw error;
            }
            // prepare chunked read
            function readStep(data : Buffer):Bool {
                sfs(data, fileStart);
                fileStart = box.appendBuffer( data );
                @ignore return !infoParsed;
            }
            // when read is complete
            function readComplete():Void {
                trace('chunked read has stopped');
            }

            // initiate chunked-read
            chunkedRead(path, chunkSize, readStep, readComplete, readReject);
        });
    }

    /**
      * chunked file-read
      */
    private function chunkedRead(path:Path, chunkSize:Int, step:Buffer->Bool, complete:Void->Void, reject:Dynamic->Void):Void {
        Nfs.open(path.toString(), 'r', function(err, fid:Int) {
            if (err != null) {
                elog( err );
                reject( err );
            }

            function readNextChunk():Void {
                var buf:Buffer = new Buffer( chunkSize );
                Nfs.read(fid, buf, 0, chunkSize, null, function(err, nread, b) {
                    if (err != null) {
                        reject( err );
                        return ;
                    }

                    if (nread == 0) {
                        try {
                            return Nfs.closeSync( fid );
                        }
                        catch (error : Dynamic) {
                            return reject( error );
                        }
                        /*
                        Nfs.close(fid, function(err) {
                            if (err != null) {
                                reject( err );
                                return ;
                            }
                            complete();
                        });
                        */
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
                                reject( err );
                                return ;
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
    private inline function elog(error : Dynamic) {
        untyped __js__('console.error')( error );
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
