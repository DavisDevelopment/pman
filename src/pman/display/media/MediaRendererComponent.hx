package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.audio.AudioPipeline;
import pman.display.media.audio.AudioPipelineNode;
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
using tannus.async.Asyncs;

class MediaRendererComponent {
    /* Constructor Function */
    public function new():Void {
        viewport = new Rect();
        _attachedEvent = new OnceSignal();
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
    public function attached(done : VoidCb):Void {
        this.player = pman.Globals.player;
        _attached = true;
        done();
    }

    /**
      * called when [this] gets detached from the media renderer
      */
    public function detached(done : VoidCb):Void {
        _attached = false;
        renderer = null;
        done();
    }

    /**
      * check whether [this] is attached to a renderer
      */
    public inline function isAttached():Bool {
        return _attached;
    }

    /**
      * announce that [this] has been successfully attached to something
      */
    public inline function announceAttached():Void {
        _attachedEvent.announce();
    }

    /**
      * ensure that when [action] is invoked, [this] has been attached
      */
    public function whenAttached(action: Void->Void):Void {
        if (_attached && _attachedEvent.isReady()) {
            action();
        }
        else {
            _attachedEvent.on( action );
        }
    }

    /**
      * check whether [this] is attached to [renderer]
      */
    public inline function isAttachedTo(renderer: MediaRenderer):Bool {
        return (isAttached() && (this.renderer == renderer) && renderer.components.has( this ));
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

    private var _attached:Bool = false;
    private var _attachedEvent:OnceSignal;
}

private typedef Mor = Lmor<MediaObject>;
