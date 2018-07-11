package pman.pmbash;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.pmbash.commands.*;

import haxe.extern.EitherType as Either;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class Interp extends Interpreter {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      * initialize all pmbash commands
      */
    override function __initCommands():Void {
        function alias(code:String)
            return new AliasCommand( code );

        commands = [
            'exit' => new ExitCommand(),
            'relaunch' => new RestartCommand(),
            'playlist' => new PlaylistCommand(),
            'pl' => new PlaylistCommand(),
            'player' => new PlayerCommand(),
            'track' => new TrackCommand(),
            'media' => new MediaCommand(),
            'mark' => new BookmarkCommand(),
            'play' => alias('player play'),
            'pause' => alias('player pause'),
            'mute' => alias('player mute'),
            'unmute' => alias('player unmute'),
            'next' => alias('player next'),
            'prev' => alias('player prev'),
            'previous' => alias('player previous'),
            'clear' => alias('pl clear'),
            'plsave' => alias('pl save'),
            'plexport' => alias('pl export'),
            'plshuffle' => alias('pl shuffle'),
            'speed' => alias('player speed'),
            'slow' => alias("speed $pbr_slow"),
            'veryslow' => alias("speed $pbr_veryslow"),
            'superslow' => alias("speed $pbr_superslow"),
            'fast' => alias("speed $pbr_fast"),
            'veryfast' => alias("speed $pbr_veryfast"),
            'superfast' => alias("speed $pbr_superfast"),
            'volume' => alias('player volume'),
        ];
    }

    /**
      * initialize environment variables
      */
    override function __initEnvironment():Void {
        super.__initEnvironment();
        if (this.environment == null)
            environment = new Dict();

        env({
            pbr_slow: '82',
            pbr_veryslow: '62',
            pbr_superslow: '40',
            pbr_fast: '110',
            pbr_veryfast: '178',
            pbr_superfast: '230'
        });
    }
}
