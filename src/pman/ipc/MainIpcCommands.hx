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

class MainIpcCommands {
    /* Constructor Function */
    public function new(bg : Background):Void {
        this.bg = bg;
    }

/* === Instance Methods === */

    /**
      * bind commands
      */
    public function bind():Void {
        inline function b(name, f) Ipc.on('command:$name', f);

        b('Reload', function() {
            electron.ext.App.relaunch();
            bg.close();
        });
        b('UpdateMenu', function() bg.updateMenu());
        b('GetLaunchInfo', function() {
            send(bg.playerWindow, 'LaunchInfo', [bg.launchInfo()]);
        });

        Ipc.on('command:HttpServe', function(event, spath:String) {
            var path = new Path(spath);
            var id = bg.httpServe( path );
            trace('$path => $id');
            event.returnValue = id;
        });
    }

    /**
      * send pmbash code to the player window to be executed
      */
    public function execInPlayer(code : String):Void {
        send(bg.playerWindow, 'Exec', [code]);
    }

    /**
      * display a textual notification
      */
    public function notify(info:Dynamic, ?t:EitherType<BrowserWindow, WebContents>):Void {
        if (!(info is String))
            info = haxe.Json.stringify( info );
        var dest = bg.playerWindow;
        
        // if there is no renderer window with which to display a notification
        if (dest == null) {
            //TODO use native notifications
        }
        else {
            send(dest, 'Notify', [info]);
        }
    }

    /**
      * send command
      */
    public function send(w:EitherType<BrowserWindow, WebContents>, cmd:String, ?args:Array<Dynamic>):Void {
        var c : WebContents;
        if (!(w is WebContents))
            c = cast(w, BrowserWindow).webContents;
        else c = cast w;
        var params:Array<Dynamic> = ['command:$cmd'];
        if (args != null)
            params = params.concat( args );
        Reflect.callMethod(c, c.send, params);
    }

/* === Instance Fields === */

    public var bg : Background;
}
