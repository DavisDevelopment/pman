package pman.ww.workers;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.sys.FSEntry;

import pman.ww.WorkerPacket;
import pman.ww.WorkerPacket as Packet;
import pman.ww.workers.*;

import pman.media.MediaSource;
import pman.db.*;
import pman.async.*;
import pman.async.ReadStream;
import pman.ww.workers.HDDProbeInfo;

import hscript.Parser;
import hscript.Interp;

import Slambda.fn;
import Reflect.compare;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using pman.async.VoidAsyncs;
using hscript.Tools;
using pman.tools.HsTools;

class HDDProbe extends Processor {
/* === Instance Methods === */

    override function __listen__():Void {
        __initInterp();
        on('open', _open);
    }

    /**
      * do the stuff
      */
    private function _open(si : HDDSProbeInfo):Void {
        compare(1, 2);
        var i:HDDProbeInfo<Dynamic> = decodeProbeInfo( si );
        trace( i );
        _streamDiskProbe( i );
    }

    // handle read-stream requests
    private function _streamDiskProbe(info : HDDProbeInfo<Dynamic>):Void {
        var ms:Path->MediaSource = fn(MediaSource.MSLocalPath( _ ));
        var sources = info.paths;
        var ssteps:Array<VoidAsync> = [];
        for (src in sources) {
            ssteps.push(function(done) {
                var hunk:Array<Path> = probe(src, info.filter);
                var chunks:Array<Array<Path>> = hunk.chunk( 5 );
                var csteps:Array<VoidAsync> = [];
                for (chunk in chunks) {
                    if (info.sort != null) {
                        chunk.sort( info.sort );
                    }
                    csteps.push(function(next) {
                        send(
                            'packet',
                            RSPacket.RSPData(chunk.map( ms )),
                            'haxe'
                        );
                        defer(next.void());
                    });
                }
                csteps.series(function(?err) {
                    done( err );
                });
            });
        }
        ssteps.series(function(?error : Dynamic) {
            if (error != null) {
                send('error', error, 'haxe');
            }
            else {
                send('packet', RSPacket.RSPClose, 'haxe');
            }
        });
    }

    /**
      * get list of paths to openable files in the given Directory
      */
    private function probe(path:Path, ?validate:Path->Bool):Array<Path> {
        var filter = electron.ext.FileFilter.ALL;
        var dir:Directory = new Directory( path );
        var results:Array<Path> = new Array();
        for (e in dir.entries) {
            switch ( e.type ) {
                case FSEntryType.File( file ):
                    if (validate == null || validate( file.path ))
                        results.push( file.path );

                case FSEntryType.Folder( sub ):
                    if (validate == null || validate( sub.path ))
                        results = results.concat(probe(sub.path, validate));
            }
        }
        return results;
    }

    /**
      * convert the 'raw' probe info provided by the parent thread to probe info
      */
    private function decodeProbeInfo<T>(spi : HDDSProbeInfo):HDDProbeInfo<T> {
        var pi:HDDProbeInfo<T> = {
            paths: spi.paths.map.fn(new Path( _ ))
        };
        if (spi.filter != null) {
            var fe = spi.filter.expr().funce();
            pi.filter = untyped fe.func( interp );
        }
        if (spi.sort != null) {
            var fe = spi.sort.expr().funce();
            pi.sort = untyped fe.func( interp );
        }
        return pi;
    }

    /**
      * initialize the hscript interpreter
      */
    private function __initInterp():Void {
        interp = new Interp();
        interp.variables['Reflect'] = Reflect;
    }

    private var interp : Interp;
}
