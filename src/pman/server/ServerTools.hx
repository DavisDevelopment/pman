package pman.server;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.node.Fs as NodeFs;
import tannus.node.*;

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



class ServerTools {
    /**
      * perform a chunked-read of the given File
      */
    public static function chunkedRead(path:Path, chunkSize:Int, step:ByteArray->Bool, complete:Void->Void, reject:Dynamic->Void):Void {
        function map_buffer(buffer : Buffer):Bool {
            var bytes = ByteArray.ofData( buffer );
            return step( bytes );
        }
        chunkedReadRaw(path, chunkSize, map_buffer, complete, reject);
    }
    public static function chunkedReadRaw(path:Path, chunkSize:Int, step:Buffer->Bool, complete:Void->Void, reject:Dynamic->Void):Void {
        // open the file in 'read' mode
        NodeFs.open(path.toString(), 'r', function(err:Null<Dynamic>, fid:Int) {
            // handle error opening file
            if (err != null) {
                throw err;
            }

            // function to read the 'next' chunk
            function readNextChunk():Void {
                // create empty Buffer to hold new data
                var buf:Buffer = new Buffer( chunkSize );

                // read data into that buffer
                NodeFs.read(fid, buf, 0, chunkSize, null, function(err:Null<Dynamic>, nread:Int, b) {
                    // handle error reading chunk
                    if (err != null) {
                        reject( err );
                        return ;
                    }

                    // if 0 bytes were read
                    if (nread == 0) {
                        // then we're done reading, close the file
                        NodeFs.close(fid, function(err:Null<Dynamic>) {
                            // handle error closing file
                            if (err != null) {
                                reject( err );
                                return ;
                            }
                            // announce completion
                            complete();
                        });
                    }

                    // create new Buffer that will contain the read data, with all blank trailing data removed
                    var data : Buffer;
                    // if the read data is smaller than defined chunk size
                    if (nread < chunkSize) {
                        // trim excess off
                        data = buf.slice(0, nread);
                    }
                    // otherwise
                    else {
                        // copy reference
                        data = buf;
                    }

                    // pass trimmed data to caller, checking that next chunk should be read
                    var continu = step( data );
                    if ( continu ) {
                        readNextChunk();
                    }
                    // if we've been told not to read next chunk
                    else {
                        NodeFs.close(fid, function(err) {
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
}
