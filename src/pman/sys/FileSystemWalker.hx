package pman.sys;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.storage.fs.async.EntryType;
import edis.storage.fs.async.EntryType.WrappedEntryType as Wet;
import edis.Globals.*;

import pman.sys.FSWFilter;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

import Slambda.fn;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;
using pman.sys.FSWFilterTools;

class FileSystemWalker {
    /* Constructor Function */
    public function new(options: FileSystemWalkerOptions):Void {
        paths = new Array();
        queue = new Array();
        pqueue = new Array();
        plqueue = new Array();
        fs = nullOr(options.fs, FileSystem.node());
        filters = new Array();
        fileFilters = new Array();
        directoryFilters = new Array();
        events = {
            processFile: new Signal()
        };

        if (options.filters != null) {
            if ((options.filters is Array<FSWFilter>)) {
                for (x in (options.filters : Array<FSWFilter>)) {
                    addFilter( x );
                    switch ((x : FSWFilter)) {
                        case FilterFile(x):
                            fileFilters.push( x );

                        case FilterDirectory(x):
                            directoryFilters.push( x );

                        default:
                            null;
                    }
                }
            }
            else {
                var of = (options.filters : {file:Array<FSWFileFilter>, directory:Array<FSWDirectoryFilter>});
                fileFilters = of.file.copy();
                directoryFilters = of.directory.copy();
            }
        }

        for (x in options.roots) {
            addSearchPath( x );
        }
    }

/* === Instance Methods === */

    public function start(complete: VoidCb):Void {
        [
            queuePaths.bind(paths, _),
            step
        ].series( complete );
    }

    /**
      * method that handles one iteration of the walking algorithm
      */
    private function step(done: VoidCb):Void {
        var finished = [true];
        defer(function() {
            // build parallel-executing list of asynchronous tasks
            vbatch(function(add, exec) {
                // get the current 'chunk' of entries
                var chunk = _shift();
                trace( chunk );

                // we're done if there is no next chunk
                if (chunk.empty()) {
                    return exec( finished );
                }
                // as long as there is a next chunk
                else {
                    // schedule processing of each entry
                    for (entry in chunk) {
                        add(function(next: VoidCb) {
                            visitEntry(entry, next);
                        });
                    }

                    // execute
                    exec();
                }
            }, 
            function(?error) {
                if (error != null) {
                    if (error == finished) {
                        done();
                    }
                    else {
                        done( error );
                    }
                }
                else {
                    defer(function() {
                        step( done );
                    });
                }
            });
        });
    }

    /**
      * add a Path to be searched next cycle
      */
    public function addSearchPath(path:Path, prepend:Bool=false):FileSystemWalker {
        if ( prepend ) {
            paths.unshift( path );
        }
        else {
            paths.push( path );
        }
        return this;
    }

    /**
      * add a FSWFilter 
      */
    public function addFilter(filter: FSWFilter):FileSystemWalker {
        filters.push( filter );
        return this;
    }

    public function addFileFilter(filter: FSWFileFilter):FileSystemWalker {
        fileFilters.push( filter );
        return this;
    }

    public function addDirFilter(filter: FSWDirectoryFilter):FileSystemWalker {
        directoryFilters.push( filter );
        return this;
    }

    public function onFileProcess(f: File->Void):FileSystemWalker {
        events.processFile.on( f );
        return this;
    }

    /**
      * handle an queue entry
      */
    private function visitEntry(entry:Wet, done:VoidCb):Void {
        switch ( entry ) {
            // File Entry
            case ETFile( file ):
                shouldProcessFile( file )
                .nope(done.void())
                .yep(function() {
                    processFile(file, done);
                })
                .unless(done.raise());

            case ETDirectory( dir ):
                shouldVisitDirectory( dir )
                .nope(done.void())
                .yep(function() {
                    trace('should visit folder');
                    visitDirectory(dir, done);
                })
                .unless(done.raise());
        }
        trace( entry );
    }

    /**
      * extract desired data from file
      */
    private function processFile(file:File, done:VoidCb):Void {
        defer(function() {
            events.processFile.call( file );

            done();
        });
    }

    /**
      * load and queue up all entries in [dir]
      */
    private function visitDirectory(dir:Directory, done:VoidCb):Void {
        dir.entries(function(?error, ?entries:Array<Entry>) {
            if (error != null) {
                done( error );
            }
            else if (!entries.empty()) {
                trace(entries.map.fn(_.path.toString()));
                //_unshifts(entries.map(x -> x.wrapped()));
                for (e in entries) {
                    _push(e.wrapped());
                }
                defer(done.void());
            }
            else {
                done('Error: No data');
            }
        });
    }

    private function shouldProcessFile(file:File):BoolPromise {
        return Promise.create({
            var fail = {v:false};
            vsequence(function(add, exec) {
                for (test in fileFilters) {
                    add(function(next) {
                        test
                        .evaluate( file )
                        .nope(next.raise().bind(fail))
                        .yep(next.void())
                        .unless(next.raise());
                    });
                }
                exec();
            }, function(?error:Dynamic) {
                if (error != null) {
                    if (error == fail) {
                        return false;
                    }
                    else {
                        throw error;
                    }
                }
                else {
                    return true;
                }
            });
        }).bool();
    }

    private function shouldVisitDirectory(dir:Directory):BoolPromise {
        return Promise.create({
            if (directoryFilters.empty()) {
                return true;
            }
            else {
                var fail = {v:false};
                vsequence(function(add, exec) {
                    for (test in directoryFilters) {
                        add(function(next) {
                            test
                            .evaluate( dir )
                            .nope(next.raise().bind(fail))
                            .yep(next.void())
                            .unless(next.raise());
                        });
                    }
                    exec();
                }, function(?error:Dynamic) {
                    if (error != null) {
                        if (error == fail) {
                            return false;
                        }
                        else {
                            throw error;
                        }
                    }
                    else {
                        return true;
                    }
                });
            }
        })
        .always(function() {
            trace('[shouldVisitDirectory] resolved');
        })
        .bool();
    }

    /**
      * queue up a list of paths
      */
    private function queuePaths(paths:Iterable<Path>, done:VoidCb):Void {
        vbatch(function(add, exec) {
            for (path in paths) {
                add(queuePath.bind(path, _));
            }
            exec();
        }, done.wrap(function(_, ?error) {
            paths = new Array();
            _( error );
        }));
    }

    /**
      * add a Path to the queue
      */
    private function queuePath(path:Path, done:VoidCb):Void {
        fs.get( path ).transform(entry -> entry.wrapped()).then(function(entry: Wet) {
            defer(function() {
                _push( entry );
                defer(done.void());
            });
        }, done.raise());
    }

    private function queueEntry(entry:Entry, done:VoidCb):Void {
        defer(function() {
            _push(entry.wrapped());
            defer(done.void());
        });
    }

    /**
      * 
      */
    public function testEntry(entry:Wet, filter:FSWFilter, ?cb:Cb<Bool>):BoolPromise {
        return new Promise(function(yield, raise) {
            inline function yeah() return yield( true );
            inline function nope() return yield( false );

            switch ( entry ) {
                case null:
                    raise("wut the shit");

                case Wet.ETFile( file ):
                    switch ( filter ) {
                        // File-specific filter
                        case FSWFilter.FilterFile( file_filter ):
                            //TODO

                        case other:
                            echo({
                                filter: other,
                                entry: entry,
                                message: 'Non-File filter'
                            });
                            return nope();
                    }

                case ETDirectory(dir):
                    switch ( filter ) {
                        // Directory-Specific filters
                        case FSWFilter.FilterDirectory( dir_filter ):
                            //TODO

                        case other:
                            echo({
                                filter: other,
                                entry: entry,
                                message: 'Non-Directory filter'
                            });
                            return nope();
                    }

                case other:
                    raise('Unexpected ${other}');
            }
        }).toAsync( cb ).bool();
    }

    /**
      * reorder [paths]
      */
    private function sortPaths():Void {
        paths.sort(function(a, b) {
            return a.compareTo( b );
        });
    }

    private function _push(entry:Wet):Void {
        var chunk:Array<Wet> = queue.last();
        if (chunk == null) {
            queue.push(chunk = new Array());
        }
        else if (chunk.length >= maxChunkLength) {
            queue.push(chunk = new Array());
        }
        chunk.push( entry );
    }

    private function _unshift(entry:Wet):Void {
        var chunk:Array<Wet> = queue[0];
        if (chunk == null || chunk.length >= maxChunkLength) {
            queue.unshift(chunk = new Array());
        }
        chunk.push( entry );
    }

    private function _unshifts(entries:Array<Wet>):Void {
        for (entry in entries) {
            _unshift( entry );
        }
    }

    private inline function _shift():Array<Wet> {
        return queue.shift();
    }

/* === Instance Fields === */

    public var fs: FileSystem;
    public var filters: Array<FSWFilter>;
    public var fileFilters: Array<FSWFileFilter>;
    public var directoryFilters: Array<FSWDirectoryFilter>;
    
    private var events: FileSystemWalkerEvents;
    private var paths: Array<Path>;
    private var queue: Array<Array<Wet>>;
    private var pqueue: Array<Array<File>>;
    private var plqueue: Array<File>;
    
    private var maxChunkLength:Int = 10;
}

typedef FileSystemWalkerOptions = {
    ?fs: FileSystem,
    ?filters: EitherType<Array<FSWFilter>, {file:Array<FSWFileFilter>, directory:Array<FSWDirectoryFilter>}>,
    roots: Array<Path>
};

typedef FileSystemWalkerEvents = {
    processFile: Signal<File>
};
