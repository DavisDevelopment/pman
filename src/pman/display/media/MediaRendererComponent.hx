package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.AudioPipeline;
import pman.display.media.LocalMediaObjectRenderer as Lmor;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

class MediaRendererComponent {
    /* Constructor Function */
    public function new():Void {
        viewport = new Rect();
    }

/* === Instance Methods === */

    /**
      * render visualization
      */
    public function render(stage:Stage, c:Ctx):Void {
        //TODO
    }

    /**
      * update data associated with visualization
      */
    public function update(stage : Stage):Void {
        viewport = player.view.rect;
    }

    /**
      * called when [this] gets attached to the media renderer
      */
    public function attached(done : Void->Void):Void {
        this.player = pman.Globals.player;
        done();
    }

    /**
      * called when [this] gets detached from the media renderer
      */
    public function detached(done : Void->Void):Void {
        defer( done );
    }

/* === Computed Instance Fields === */

    public var controller(get, never):MediaController;
    private inline function get_controller():MediaController return renderer.mediaController;

    public var mediaObject(get, never):MediaObject;
    @:access( pman.display.media.LocalMediaObjectRenderer )
    private inline function get_mediaObject():MediaObject return untyped renderer.mediaObject;

    private var mo(get, never):MediaObject;
    private inline function get_mo():MediaObject return mediaObject;

    private var mc(get, never):MediaController;
    private inline function get_mc():MediaController return controller;

    private var mr(get, never):Mor;
    private inline function get_mr():Mor return renderer;

/* === Instance Fields === */

    public var renderer : Mor;
    public var player : Null<Player> = null;
    public var viewport : Rect<Float>;
}

private typedef Mor = Lmor<MediaObject>;
