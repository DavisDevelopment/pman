package pman.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.main.IpcMain as Ipc;
import electron.main.BrowserWindow;
import electron.main.WebContents;
import haxe.extern.EitherType;
import electron.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class MainIpcCommands extends BaseIpcCommands {
    /* Constructor Function */
    public function new(bg : Background):Void {
        super();

        this.bg = bg;
    }

/* === Instance Methods === */

    /**
      * bind commands
      */
    public function bind():Void {
    }

    /**
      * send pmbash code to the player window to be executed
      */
    public function execInPlayer(code : String):Void {
        send('Exec', code);
    }

    /**
      * post a message to the player window
      */
    override function _post(channel:String, data:Dynamic):Void {
        bg.playerWindow.webContents.send(channel, data);
    }

    /**
      * listen for a message on
      */
    override function _onMessage(channel:String, handler:Dynamic->Void):Void {
        Ipc.on(channel, function(event, ?data:Dynamic) {
            handler( data );
        });
    }

/* === Instance Fields === */

    public var bg : Background;
}
