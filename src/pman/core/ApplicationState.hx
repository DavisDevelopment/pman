package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.events.EventEmitter;
import pman.ds.*;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.rtti.Meta;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.macro.MacroTools;

class ApplicationState {
    /* Constructor Function */
    public function new():Void {
        player = new PlayerConfig();
        sessMan = new SessManConfig();
        playback = new PlaybackConfig();
        rendering = new RenderingConfig();
    }

/* === Instance Methods === */

    /**
      get the metadata for the given type
     **/
    static inline function _meta<T:Model>(c: Class<T>):Anon<Array<Dynamic>> {
        return Meta.getType( c );
    }

/* === Instance Fields === */

    public var player:PlayerConfig;
    public var sessMan:SessManConfig;
    public var playback:PlaybackConfig;
    public var rendering:RenderingConfig;
}

@saveName('state/cfg.player.dat')
class PlayerConfig extends ProxyModel<PlayerConfigType> {

}

@saveName('state/cfg.session.dat')
class SessManConfig extends ProxyModel<SessManConfigType> {

}

@saveName('state/cfg.playback.dat')
class PlaybackConfig extends ProxyModel<PlaybackConfigType> {

}

@saveName('state/cfg.render.dat')
class RenderingConfig extends ProxyModel<RenderingConfigType> {

}

/**
  underlying type for player-state
 **/
private class PlayerConfigType {
    /* -- general player-related state options -- */
    var showSnapshot:Bool = true;
    var showAlbumArt:Bool = true;
    var mediaTypeSpecificConfig:Bool = false;

    var mediaConfig:PlayerMediaConfig = {{
        visualizer: 'spectograph'
    };};
    var audioConfig:PlayerAudioConfig = {{
        visualizer: 'spectograph'
    };};
    var videoConfig:PlayerVideoConfig = {{
        visualizer: 'spectograph',
        showVisualizer: false,
        audioOnly: false
    };};
}

typedef PlayerMediaConfig = {
    @:defaultTo('spectograph')
    var visualizer:String;
}

typedef PlayerAudioConfig = {
    >PlayerMediaConfig,
    //
}

typedef PlayerVideoConfig = {
    >PlayerMediaConfig,

    var audioOnly:Bool;
    var showVisualizer:Bool;
}

/**
  underlying type for session management configuration
 **/
private class SessManConfigType {
    var restorePreviousSession:Bool = true;
    var autoSaveSession:Bool = true;
    var sessionToRestore:String = 'session.dat';
    var sessionSaveName:String = 'session.dat';
    var autoRestoreSession:Bool = false;
}

/**
  underlying type for playback configuration
 **/
private class PlaybackConfigType {
    /* -- misc config options -- */
    var autoPlay:Bool = true;

    /* -- playback options -- */
    var volume:Float = 1.0;
    var speed:Float = 1.0;
    var shuffle:Bool = false;
    var repeat:Int = 0;
    var muted:Bool = false;
}

/**
  underlying type for rendering/display configuration
 **/
private class RenderingConfigType {
    var directRender:Bool = true;
}
