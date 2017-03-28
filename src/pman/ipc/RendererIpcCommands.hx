package pman.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;
import tannus.node.ChildProcess;

import crayon.*;

import electron.ext.*;
import electron.renderer.IpcRenderer as Ipc;
import electron.ext.Dialog;
import electron.Tools.defer;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;
import pman.ww.Worker;

import Std.*;
import tannus.internal.CompileTime in Ct;
import tannus.TSys as Sys;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class RendererIpcCommands {
    /* Constructor Function */
    public function new(m : BPlayerMain):Void {
        this.main = m;
    }

/* === Instance Methods === */

    /**
      * bind commands
      */
    public function bind():Void {
        inline function b(name, f) {
            Ipc.on('command:$name', f);
        }

        b('OpenFile', function() player.selectAndOpenFiles());
        b('OpenDirectory', function() player.selectAndOpenDirectory());
        b('SavePlaylist', function() player.savePlaylist());
        b('TogglePlaylist', function() player.togglePlaylist());
        b('ClearPlaylist', function() player.clearPlaylist());
        b('ShufflePlaylist', function() player.shufflePlaylist());
        b('SaveSession', function() player.saveState());
        b('LoadSession', function(e, name:String) {
            player.loadState( name );
        });
    }

    /**
      * send a command
      */
    public function send(cmd:String, ?args:Array<Dynamic>):Void {
        var params:Array<Dynamic> = ['command:$cmd'];
        if (args != null)
            params = params.concat( args );
        Reflect.callMethod(Ipc, Ipc.send, params);
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return main.player;

/* === Instance Fields === */

    public var main : BPlayerMain;
}
