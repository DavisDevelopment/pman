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
        /*
        b('Reload', function() {
            electron.ext.App.relaunch();
            bg.close();
        });

        b('UpdateMenu', function() bg.updateMenu());

        b('GetLaunchInfo', function() {
            send('LaunchInfo', bg.launchInfo());
        });

        Ipc.on('command:HttpServe', function(event, spath:String) {
            var path = new Path(spath);
            var id = bg.httpServe( path );
            trace('$path => $id');
            event.returnValue = id;
        });
        */

        on('betty', function(packet) {
            trace( packet );
        });

        on('GetLaunchInfo', function(packet) {
            trace('launch-info requested');

            packet.reply(bg.launchInfo());
        });
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
