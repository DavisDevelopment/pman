package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

class AudioManager {
    /* Constructor Function */
    public function new(renderer : LocalMediaObjectRenderer<MediaObject>):Void {
        this.renderer = renderer;
        active = false;
        treeBuilders = new Array();
    }

/* === Instance Methods === */

    /**
      * Activate [this]
      */
    public function activate(?done : Void->Void):Void {
        if ( !active ) {
            buildTree(function() {
                active = true;
                if (done != null)
                    done();
            });
        }
        else if (done != null) {
            done();
        }
    }

    /**
      * Deactivate [this]
      */
    public function deactivate(?done : Void->Void):Void {
        if ( !_closing ) {
            _closing = true;
            try {
                if (context != null) {
                    context.close(function() {
                        active = false;
                        _closing = false;
                        context = null;
                        source.disconnect();
                        source = null;
                        destination = null;
                        if (done != null)
                            defer( done );
                    });
                }
                else {
                    defer(function() if (done != null) done());
                }
            }
            catch (error : Dynamic) {
                defer(function() if (done != null) done());
            }
        }
    }

    /**
      * build out the AudioNode tree
      */
    @:access( pman.display.media.LocalMediaObjectRenderer )
    public function buildTree(done : Void->Void):Void {
        (if (context != null) context.close else defer)(function() {
            context = new AudioContext();
            source = context.createSource(untyped renderer.mediaObject);
            destination = context.destination;

            source.connect( destination );

            for (f in treeBuilders) {
                f( this );
            }

            defer( done );
        });
    }

    /**
      * rebuild the tree
      */
    public function rebuildTree(done : Void->Void):Void {
        deactivate(function() {
            activate( done );
        });
    }

/* === Instance Fields === */

    public var renderer : LocalMediaObjectRenderer<MediaObject>;
    public var context : AudioContext;
    public var source : AudioSource;
    public var destination : AudioDestination;

    public var active(default, null):Bool;

    public var treeBuilders : Array<AudioManager -> Void>;

    private var _closing : Bool = false;
}
