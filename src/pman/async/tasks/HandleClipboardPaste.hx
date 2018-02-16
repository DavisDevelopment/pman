package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.File;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import pman.bg.media.*;
import pman.bg.media.MediaSource;
import pman.media.PathListConverter;
import pman.media.FileListConverter;
import pman.media.Track;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;
using pman.media.MediaTools;

class HandleClipboardPaste extends Task1 {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * handle clipboard-pasted data
      */
    public function handleString(s:String, ?callback:VoidCb):Void {
        clipData = s;

        run( callback );
    }

    /**
      * execute [this]
      */
    override function execute(done: VoidCb):Void {
        steps = new Array();
        //sources = new Array();
        tracks = new Array();

        if (!clipData.hasContent()) {
            done();
        }
        else {
            try {
                // create variable for list of 'data's
                var datas:Array<String> = new Array();

                // if it is a multiline, chunked piece of data, split it up
                if (clipData.has('\n')) {
                    datas = clipData.split( '\n' );
                }

                // if it's separated by semicolons, split that up too
                else if (clipData.has(';')) {
                    datas = clipData.split( ';' );
                }

                // otherwise, just add the given string
                else {
                    datas = [clipData];
                }

                // now, perform necessary processing on those strings
                process_strings(datas, done.sub({
                    // then, wrap things up
                    defer(finalize.bind(done));
                }));
            }
            catch (error: Dynamic) {
                done( error );
            }
        }
    }

    /**
      * process an Array of Strings
      */
    private function process_strings(datas:Array<String>, done:VoidCb):Void {
        var paths:Array<Path> = new Array();
        
        // iterate over each data-string
        for (data in datas) {
            // trim off unnecessary whitespace from [data]
            data = data.trim();

            // ensure that "file://" urls get treated properly as filesystem-paths
            if (data.isUri()) {
                // if it has a "file" protocol
                if (data.protocol() == 'file') {
                    // strip it of that protocol and convert it to a path
                    data = data.afterProtocol().toFilePath().toString();
                }
            }

            // if [data] is a file-system path
            if (data.isPath()) {
                // add it to a list of such paths
                paths.push( data );
            }

            // otherwise if it's a URI of any kind
            else if (data.isUri()) {
                // add a step
                step(function(next: VoidCb) {
                    defer(function() {
                        try {
                            // convert [data] to a MediaSource
                            var source:MediaSource = data.toMediaSource();

                            // error out if that's [null]
                            if (source == null) {
                                throw 'failed to parse the given String to a MediaSource';
                            }

                            // otherwise push [source] onto [tracks]
                            else {
                                tracks.push(source.toTrack());
                            }

                            // move on to the next step
                            next();
                        }
                        // handle errors
                        catch (error: Dynamic) {
                            next( error );
                        }
                    });
                });
            }

            // if it's anything else, throw an error
            else {
                throw 'unhandled clipboard data';
            }
        }

        // parse the paths that have been gathered thus far
        parse_paths(paths, done);

    }

    /**
      * parse a list of FileSystem paths
      */
    private function parse_paths(paths:Array<Path>, next:VoidCb):Void {
        // do nothing at all if [paths] has no items in it
        if (paths.empty()) {
            defer(next.void());
        }
        else {
            try {
                // create the pathlist converter
                var plc = new PathListConverter();

                // create the filelist converter
                var flc = new FileListConverter();

                // convert the list of paths into an expanded list of paths that only refer to file-paths
                paths = plc.convert( paths );

                // convert the list of paths into a list of files
                var files:Array<File> = paths.map(function(path: Path):File {
                    return new File( path );
                });

                // convert the list of files into an expanded list of Track objects
                var playlist = flc.convert( files );

                // append all items of [playlist] to [tracks]
                for (track in playlist) {
                    tracks.push( track );
                }

                // defer 'completion' to the next stack
                defer(next.void());
            }
            catch (error: Dynamic) {
                next( error );
            }
        }
    }

    /**
      * eliminate any/all duplicate tracks
      */
    private function eliminate_duplicate_tracks(next: VoidCb):Void {
        var trackSet:Set<Track> = new Set();
        trackSet.pushMany( tracks );

        tracks = trackSet.toArray();
        next();
    }

    /**
      * add tracks to the Player's queue
      */
    private function queue_tracks(next: VoidCb):Void {
        player.addItemList(tracks, function() {
            next();
        });
    }

    /**
      * method to wrap up all necessary computations and declare completion
      */
    private function finalize(done: VoidCb):Void {
        // eliminate all duplicate entries in [tracks]
        step( eliminate_duplicate_tracks );

        // add all tracks to the player
        step( queue_tracks );

        // execute all queued steps
        steps.series(done.sub({
            defer(_cb_.void());
        }));
    }

    /**
      * add a functional "step" to the list
      */
    private inline function step(va: VoidAsync):Void {
        steps.push( va );
    }

/* === Instance Fields === */

    public var clipData: String;

    private var steps: Array<VoidAsync>;
    //private var sources: Array<MediaSource>;
    private var tracks: Array<Track>;

/* === Static Methods === */

    /**
      * static shorthand method for handling clipboard data
      */
    public static inline function handle(s:String, ?callback:VoidCb):Void {
        new HandleClipboardPaste().handleString(s, callback);
    }
}
