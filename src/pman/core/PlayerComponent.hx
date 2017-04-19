package pman.core;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;

import pman.core.*;
import pman.media.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class PlayerComponent {
    /* Constructor Function */
    public function new():Void {
        player = BPlayerMain.instance.player;
    }

/* === Instance Methods === */

    public function onAttached():Void {
        return ;
    }

    public function onDetached():Void {
        return ;
    }

    public function onTrackChanging(delta : Delta<Null<Track>>):Void {
        return ;
    }

    public function onTrackChanged(delta : Delta<Null<Track>>):Void {
        return ;
    }

    public function onTrackReady(track : Track):Void {
        return ;
    }

    public function onTick(time : Float):Void {
        return ;
    }

    public function detach():Bool {
        return player.detachComponent( this );
    }

/* === Instance Fields === */

    public var player : Player;
}
