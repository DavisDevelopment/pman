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

import haxe.Json;
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
        queue = new Chunks(maxChunkLength);
        pqueue = new Chunks(maxChunkLength);
        fs = nullOr(options.fs, FileSystem.node());
        filters = new Array();
        fileFilters = new Array();
        directoryFilters = new Array();
        events = {
            start: new VoidSignal(),
            end: new VoidSignal(),
            processStart: new VoidSignal(),
            processEnd: new VoidSignal(),
            processFile: new Signal(),
            processFileChunk: new Signal(),
            processStep: new VoidSignal(),
            walkStep: new Signal(),
            walkStart: new VoidSignal(),
            walkEnd: new VoidSignal(),
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

    /**
      * begin execution for [this] FileSystemWalker
      */
    public function start(complete: VoidCb):Void {
        // create value that is thrown as error when total completion is achieved
        var finished = [true];

        var steps:Array<VoidAsync> = [
            walk.bind(finished, _),
            process.bind(finished, _)
        ];

        steps.series(function(?error) {
            if (error != null) {
                complete( error );
            }
            else {
                trace( pqueue );
                complete();
            }
        });
    }

    /**
      * process all entries that were queued for processing in the walk procedure
      */
    public function process(?finishedToken:Dynamic, complete:VoidCb):Void {
        if (finishedToken == null) {
            finishedToken = [true];
        }

        processStep(finishedToken, complete);
    }

    private function processStep(finishedToken:Dynamic, done:VoidCb):Void {
        var chunk = pqueue.shift();
        if (chunk.empty()) {
            done( finishedToken );
        }
        else {
            handleFileChunk(function(?error) {
                if (error != null) {
                    done( error );
                }
                else {
                    defer(processStep.bind(finishedToken, done));
                }
            });
        }
    }

    /**
      * attempt to process a set of files if there are enough queued
      */
    private function processPartial(done: VoidCb):Void {
        var chunk = pqueue.shift();
        trace('partial', chunk);
        if ((chunk.hasContent() && chunk.length >= pqueue.maxLength) || (chunk.hasContent() && gatherFilesComplete)) {
            handleFileChunk(chunk, done);
        }
        else {
            defer(done.void());
        }
    }

    /**
      * perform the 'walk' part of the procedures
      */
    public function walk(?finishedToken:Dynamic, complete:VoidCb):Void {
        if (finishedToken == null) {
            finishedToken = [true];
        }

        // queue up root paths
        queuePaths(paths, function(?error) {
            // if that failed, error out
            if (error != null) {
                complete( error );
            }
            // otherwise..
            else {
                // begin the step cycle
                walkStep(finishedToken, function(?error) {
                    if (error != null) {
                        if (error == finishedToken) {
                            gatherFilesComplete = true;
                            complete();
                        }
                        else {
                            complete( error );
                        }
                    }
                    else {
                        complete();
                    }
                });
            }
        });
    }

    /**
      * method that handles one iteration of the walking algorithm
      */
    private function walkStep(finishedToken:Dynamic, done:VoidCb):Void {
        defer(function() {
            // build parallel-executing list of asynchronous tasks
            vbatch(function(add, exec) {
                // get the current 'chunk' of entries
                var chunk = queue.shift();

                // we're done if there is no next chunk
                if (chunk == null || chunk.empty()) {
                    return exec( finishedToken );
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
                    done( error );
                }
                else {
                    // schedule next step
                    defer(function() {
                        processPartial(function(?error) {
                            if (error != null) {
                                done( error );
                            }
                            else {
                                defer(walkStep.bind(finishedToken, done));
                            }
                        });
                    });
                    //defer(walkStep.bind(finishedToken, done));
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

    /**
      * add a File-specific filter
      */
    public function addFileFilter(filter: FSWFileFilter):FileSystemWalker {
        fileFilters.push( filter );
        return this;
    }

    /**
      * add a Directory-specific filter
      */
    public function addDirFilter(filter: FSWDirectoryFilter):FileSystemWalker {
        directoryFilters.push( filter );
        return this;
    }

    /**
      * handle the 'fileProcess' event
      */
    public function onFileProcess(f: File->Void):FileSystemWalker {
        events.processFile.on( f );
        return this;
    }

    /**
      * handle the 'fileChunkProcess' event
      */
    public function onFileChunkProcess(f: Array<File>->Void):FileSystemWalker {
        events.processFileChunk.on( f );
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
                    //handleFile(file, done);
                    pqueue.push( file );
                    done();
                })
                .unless(done.raise());

            // Directory Entry
            case ETDirectory( dir ):
                shouldVisitDirectory( dir )
                .nope(done.void())
                .yep(function() {
                    visitDirectory(dir, done);
                })
                .unless(done.raise());
        }
    }

    /**
      * handle a File instance
      */
    private function handleFile(file:File, done:VoidCb):Void {
        pqueue.push( file );

        // one could imagine that there could be some need for additional logic and whatnot here..
        processFile(file, done);
    }

    /**
      * handle a list of Files
      */
    private function handleFileChunk(?chunk:Array<File>, done:VoidCb):Void {
        if (pqueue.empty()) {
            return done();
        }
        else {
            if (chunk == null) {
                chunk = pqueue.shift();
            }
            if (chunk.hasContent()) {
                processFileChunk(chunk, done);
            }
            else {
                done();
            }
        }
    }

    /**
      * perform desired processing on File instance
      */
    private function processFile(file:File, done:VoidCb):Void {
        events.processFile.call( file );
        done();
    }

    /**
      * process a list of files
      */
    private function processFileChunk(chunk:Array<File>, done:VoidCb):Void {
        events.processFileChunk.call( chunk );
        vbatch(function(add, exec) {
            for (x in chunk) {
                add(processFile.bind(x, _));
            }

            defer(function() {
                exec();
            });
        }, done);
    }

    /**
      * load and queue up all entries in [dir]
      */
    private function visitDirectory(dir:Directory, done:VoidCb):Void {
        dir.entries()
        .then(function(entries: Array<Entry>) {
            trace(entries.map.fn(_.path.toString()));
            for (e in entries) {
                queue.push(e.wrapped());
            }
            defer(done.void());
        })
        .unless(done.raise());
    }

    /**
      * check whether the given File should be processed
      */
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
                queue.push( entry );
                defer(done.void());
            });
        }, done.raise());
    }

    /**
      * add an Entry to the queue
      */
    private function queueEntry(entry:Entry, done:VoidCb):Void {
        defer(function() {
            queue.push(entry.wrapped());
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

/* === Static Methods === */

    private static function _cache_file(fs:FileSystem, path:Path, done:VoidCb):Void {
        function onError(error: Dynamic) {
            done( error );
        }

        function nonExistent() {
            fs.write(path, '{}', done);
        }

        function existsButEmpty() {
            fs.write(path, '{}', done);
        }

        function existsButBroken(brokenData:ByteArray) {
            var brokenPath:Path = path.directory.plusString(path.basename + '_BROKENDATA' + path.extension);
            var newData:ByteArray = ByteArray.ofString('{}');
            vsequence(function(add, exec) {
                add(cast fs.write.bind(brokenPath, brokenData, _));
                add(cast fs.write.bind(path, newData, _));

                exec();
            }, 
            function(?error) {
                if (error != null) {
                    onError( error );
                }
                else {
                    done();
                }
            });
        }

        function exists() {
            fs.read( path ).then(function(data: ByteArray) {
                if (data.length == 0) {
                    existsButEmpty();
                }
                else {
                    try {
                        var dat:Dynamic = Json.parse(data.toString());
                        if (Reflect.isObject( dat ) && !(dat is Array<Dynamic>)) {
                            //
                        }
                        else {
                            existsButBroken( data );
                        }
                    }
                    catch (error: Dynamic) {
                        existsButBroken( data );
                    }
                }
            }, onError);
        }

        fs.exists( path ).nope( nonExistent ).yep( exists );
    }

    private static function read_cache_raw(fs:FileSystem, path:Path):Promise<JsonFileSystemWalkerCache> {
        return new Promise(function(accept, reject) {
            _cache_file(fs, path, function(?error) {
                if (error != null) {
                    return reject( error );
                }
                else {
                    fs.read( path ).then(function(data: ByteArray) {
                        try {
                            var d:Dynamic = Json.parse(data.toString());
                            if (Reflect.isObject( d )) {
                                return accept(untyped d);
                            }
                            else {
                                return reject('TypeError: Invalid cache data');
                            }
                        }
                        catch (error: Dynamic) {
                            reject( error );
                        }
                    }, reject);
                }
            });
        });
    }

    private static function read_cache(fs:FileSystem, path:Path):Promise<FileSystemWalkerCache> {
        return read_cache_raw(fs, path).transform( cache_cook );
    }

    private static function cache_cook(raw: JsonFileSystemWalkerCache):FileSystemWalkerCache {
        var cache = new FileSystemWalkerCache();
        var raw:Anon<EitherType<Bool, JsonFileSystemWalkerCache>> = raw;
        var item:EitherType<Bool, JsonFileSystemWalkerCache>, path:Path;
        
        for (key in raw.keys()) {
            path = Path.fromString( key );
            item = raw[key];

            if ((item is Bool)) {
                cache[path] = FSWCFile;
            }
            else {
                cache[path] = FSWCDirectory(cache_cook_sub(path, cast item));
            }
        }

        return cache;
    }

    private static function cache_cook_sub(root:Path, raw:JsonFileSystemWalkerCache):FileSystemWalkerSubCache {
        var sub = new FileSystemWalkerSubCache();
        var raw:Anon<EitherType<Bool, JsonFileSystemWalkerCache>> = raw;
        var item:EitherType<Bool, JsonFileSystemWalkerCache>, path:Path;

        for (key in raw.keys()) {
            path = root.plusString( key );
            item = raw[key];

            if ((item is Bool)) {
                sub[path] = FSWCFile;
            }
            else {
                sub[path] = FSWCDirectory(cache_cook_sub(path, cast item));
            }
        }

        return sub;
    }

/* === Instance Fields === */

    public var fs: FileSystem;
    public var filters: Array<FSWFilter>;
    public var fileFilters: Array<FSWFileFilter>;
    public var directoryFilters: Array<FSWDirectoryFilter>;
    
    private var events: FileSystemWalkerEvents;
    private var paths: Array<Path>;
    private var queue: Chunks<Wet>;
    private var pqueue: Chunks<File>;
    private var gatherFilesComplete:Bool = false;
    
    private var maxChunkLength:Int = 10;
}

typedef FileSystemWalkerOptions = {
    ?fs: FileSystem,
    ?filters: EitherType<Array<FSWFilter>, {file:Array<FSWFileFilter>, directory:Array<FSWDirectoryFilter>}>,
    ?chunkSize: Int,
    ?cacheFile: Path,
    roots: Array<Path>
};

typedef FileSystemWalkerEvents = {
    start: VoidSignal,
    end: VoidSignal,
    processFile: Signal<File>,
    processFileChunk: Signal<Array<File>>,
    processStep: VoidSignal,
    processStart: VoidSignal,
    processEnd: VoidSignal,
    walkStart: VoidSignal,
    walkEnd: VoidSignal,
    walkStep: Signal<Array<Wet>>,
};

private typedef FileSystemWalkerCache = Dict<Path, FSWCEntry>;
private typedef FileSystemWalkerSubCache = Map<String, FSWCEntry>;
private enum FSWCEntry {
    FSWCFile;
    FSWCDirectory(data: FileSystemWalkerSubCache);
}

private typedef JsonFileSystemWalkerCache = Dynamic<EitherType<Bool, JsonFileSystemWalkerCache>>;
