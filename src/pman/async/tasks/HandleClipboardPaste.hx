package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import pman.bg.media.*;
import pman.bg.media.MediaSource;

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
        if (!clipData.hasContent()) {
            done();
        }
        else {
            try {
                var datas:Array<String> = new Array();
                if (clipData.has('\n')) {
                    datas = clipData.split( '\n' );
                }
                else if (clipData.has(';')) {
                    datas = clipData.split( ';' );
                }
                else {
                    datas = [clipData];
                }
                process_strings(datas, done);
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
        var steps:Array<VoidAsync> = new Array();
        var sources:Array<MediaSource> = new Array();
        
        for (data in datas) {
            if (data.isUri() || data.isPath()) {
                steps.push(function(next: VoidCb) {
                    defer(function() {
                        try {
                            var source:MediaSource = data.toMediaSource();
                            if (source == null) {
                                throw 'failed to parse the given String to a MediaSource';
                            }
                            else {
                                sources.push( source );
                            }
                            next();
                        }
                        catch (error: Dynamic) {
                            next( error );
                        }
                    });
                });
            }
            else {
                throw 'unhandled clipboard data';
            }
        }

        steps.series(done.sub({
            if (sources.hasContent()) {
                _cb_.attemptWith({
                    player.addItemList(sources.map(src->src.toTrack()), _cb_.void());
                });
            }
            else {
                _cb_();
            }
        }));
    }

/* === Instance Fields === */

    public var clipData: String;

/* === Static Methods === */

    public static inline function handle(s:String, ?callback:VoidCb):Void {
        new HandleClipboardPaste().handleString(s, callback);
    }
}
