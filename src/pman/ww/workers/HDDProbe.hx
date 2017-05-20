package pman.ww;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.sys.FSEntry;

import pman.ww.WorkerPacket;
import pman.ww.WorkerPacket as Packet;

import pman.media.MediaSource;
import pman.db.*;
import pman.async.*;
import pman.async.ReadStream;

import hscript.Parser;
import hscript.Interp;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using hscript.Tools;

class HDDProbe extends Processor {
/* === Instance Methods === */

    override function __listen__():Void {
        on('open', _open);
    }

    private function _open(i : ProbeInfo):Void {

    }

    // handle read-stream requests
    private function _streamDiskProbe(info : ProbeInfo):Void {
        var ms:Path->MediaSource = fn(MediaSource.MSLocalPath( _ ));
        var sources = info.paths;
        var mediaPaths = new Array();
        for (src in sources) {
            var hunk:Array<Path> = probe( src );
            var chunks:Array<Array<Path>> = hunk.chunk( 30 );
            for (chunk in chunks) {
                send(
                    'packet',
                    RSPacket.RSPData(chunk.map( ms )),
                    'haxe'
                );
            }
        }
        defer(function() {
            send('packet', RSPacket.RSPClose, 'haxe');
        });
    }

    /**
      * get list of paths to openable files in the given Directory
      */
    private function probe(path : Path):Array<Path> {
        var filter = electron.ext.FileFilter.ALL;
        var dir:Directory = new Directory( path );
        var results:Array<Path> = new Array();
        for (e in dir.entries) {
            switch ( e.type ) {
                case FSEntryType.File( file ):
                    results.push( file.path );

                case FSEntryType.Folder( sub ):
                    results = results.concat(probe( sub.path ));
            }
        }
        return results;
    }

}

typedef ProbeInfo = {
    paths: Array<String>
};
