package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry.FSEntryType;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.MediaType;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class DirectoryProbe {
    /* Constructor Function */
    public function new():Void {
        sources = new Array();
        results = new Array();
    }

/* === Instance Methods === */

    /**
      * commence [this] probe
      */
    public function run(?done : Array<File> -> Void):Void {
        probe(function() {
            if (done != null) {
                done( results );
            }
        });
    }

    /**
      * actually perform probing
      */
    private function probe(done : Void->Void):Void {
        defer(function() {
            for (d in sources) {
                probe_dir( d );
            }
            
            defer( done );
        });
    }

    /**
      * each step in the probe process
      */
    private function probe_dir(d : Directory):Void {
        for (entry in d) {
            switch ( entry.type ) {
                case File( file ):
                    if (test_file( file )) {
                        results.push( file );
                    }

                case Folder( sub ):
                    if (test_directory( sub )) {
                        probe_dir( sub );
                    }
            }
        }
    }

    /**
      * set [this] probe's sources
      */
    public function setSources(list : Array<Directory>):Void {
        sources = list;
    }

    /**
      * method used to validate files
      */
    private function test_file(file : File):Bool {
        return true;
    }

    /**
      * method used to validate folders
      */
    private function test_directory(d : Directory):Bool {
        return true;
    }

/* === Instance Fields === */

    public var results : Array<File>;
    public var sources : Array<Directory>;
}
