package pman.display;

import tannus.ds.*;
import tannus.io.*;
import tannus.async.*;
import tannus.graphics.Color;

import pman.core.Player;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using Slambda;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using pman.bg.URITools;
using pman.bg.DictTools;

abstract PlayerInterfaceConfiguration (Player) {
    public inline function new(player: Player) {
        this = player;
    }

/* === Instance Methods === */

    public inline function keys():Iterator<String> return flags.keys();
    public inline function values():Iterator<Dynamic> return flags.iterator();

    @:to
    public inline function toDynamic():Dynamic return flags.toAnon();

    public inline function remove(name: String):Bool return flags.remove( name );
    public inline function exists(name: String):Bool return flags.exists( name );

    @:arrayAccess
    inline function get<T>(name:String):Null<T> {
        return flag( name );
    }

    @:arrayAccess
    inline function set<T>(name:String, value:T):T {
        return flag(name, value);
    }

    private inline function flag<T>(k:String, ?v:T):T {
        return this.flag(k, v);
    }

/* === Instance Fields === */

    public var audioVisualizerType(get, set): String;
    private inline function get_audioVisualizerType():String return nullOr(get('visualizer'), 'bars');
    private inline function set_audioVisualizerType(v: String):String return set('visualizer', v);

    public var videoVisualizerType(get, set): String;
    private inline function get_videoVisualizerType():String return nullOr(get('visualizer:video'), 'default');
    private inline function set_videoVisualizerType(v: String):String return set('visualizer:video', v);

    public var videoAudioOnlyType(get, set): Bool;
    private inline function get_videoAudioOnlyType():Bool return nullOr(get('video:audio-only'), false);
    private inline function set_videoAudioOnlyType(v: Bool):Bool return set('video:audio-only', v);

    public var videoShowVisualizer(get, set): Bool;
    private inline function get_videoShowVisualizer():Bool return nullOr(get('video:show-visualizer'), false);
    private inline function set_videoShowVisualizer(v: Bool):Bool return set('video:show-visualizer', v);

    private var flags(get, never):Dict<String, Dynamic>;
    private inline function get_flags():Dict<String, Dynamic> return this.flags;
}
