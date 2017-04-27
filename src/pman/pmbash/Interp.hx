package pman.pmbash;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.pmbash.commands.*;

import electron.Tools.*;

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

    override function __initCommands():Void {
        function alias(code:String)
            return new AliasCommand( code );
        commands = [
            'exit' => new ExitCommand(),
            'playlist' => new PlaylistCommand(),
            'pl' => new PlaylistCommand(),
            'player' => new PlayerCommand(),
            'play' => alias('player play'),
            'pause' => alias('player pause'),
            'mute' => alias('player mute'),
            'unmute' => alias('player unmute'),
            'next' => alias('player next'),
            'prev' => alias('player prev'),
            'previous' => alias('player previous'),
            'plclear' => alias('pl clear'),
            'plsave' => alias('pl save'),
            'plexport' => alias('pl export'),
            'ple' => alias('pl export'),
            'plshuffle' => alias('pl shuffle')
        ];
    }
}
